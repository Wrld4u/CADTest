import { Injectable } from '@nestjs/common'
import { randomUUID } from 'node:crypto'
import { RedisService } from '../../../../infrastructure/redis/redis.service'
import { PrismaService } from '../../../../infrastructure/prisma/prisma.service'
import { Prisma } from '../../../../generated/prisma/client'
import { Reservation } from '../../domain/entities/reservation.entity'
import { SeatAlreadyReservedError } from '../../domain/errors/seat-already-reserved.error'
import { ReservationRepository } from '../../domain/repositories/reservation.repository'

@Injectable()
export class PrismaReservationRepository implements ReservationRepository {
    private readonly maxInFlight: number
    private inFlight = 0
    private readonly waitQueue: Array<() => void> = []

    constructor(
        private readonly prisma: PrismaService,
        private readonly redisService: RedisService
    ) {
        const configuredLimit = Number(process.env.RESERVE_MAX_IN_FLIGHT ?? 80)
        this.maxInFlight = Number.isFinite(configuredLimit) && configuredLimit > 0 ? configuredLimit : 80
    }

    async reserve(params: { userId: string; seatId: string }): Promise<Reservation> {
        const lockAcquired = await this.redisService.tryAcquireSeatLock(params.seatId)
        if (lockAcquired === false) {
            throw new SeatAlreadyReservedError()
        }

        try {
            const insertResult = await this.withBackpressure(() =>
                this.prisma.$queryRaw<
                    Array<{
                        id: string
                        user_id: string
                        seat_id: string
                        created_at: Date
                    }>
                >(Prisma.sql`
                    INSERT INTO reservations (id, user_id, seat_id)
                    VALUES (${randomUUID()}::uuid, ${params.userId}, ${params.seatId})
                    ON CONFLICT (seat_id) DO NOTHING
                    RETURNING id, user_id, seat_id, created_at
                `)
            )

            const insertedReservation = insertResult[0]
            if (!insertedReservation) {
                if (lockAcquired === true) {
                    await this.redisService.persistSeatLock(params.seatId)
                }

                throw new SeatAlreadyReservedError()
            }

            if (lockAcquired === true) {
                await this.redisService.persistSeatLock(params.seatId)
            }

            return new Reservation(
                insertedReservation.id,
                insertedReservation.user_id,
                insertedReservation.seat_id,
                insertedReservation.created_at
            )
        } catch (error) {
            if (lockAcquired === true) {
                await this.redisService.releaseSeatLock(params.seatId)
            }

            throw error
        }
    }

    private async withBackpressure<T>(operation: () => Promise<T>): Promise<T> {
        await this.acquireSlot()

        try {
            return await operation()
        } finally {
            this.releaseSlot()
        }
    }

    private async acquireSlot(): Promise<void> {
        if (this.inFlight < this.maxInFlight) {
            this.inFlight += 1
            return
        }

        await new Promise<void>(resolve => {
            this.waitQueue.push(resolve)
        })

        this.inFlight += 1
    }

    private releaseSlot(): void {
        this.inFlight -= 1

        const next = this.waitQueue.shift()
        if (next) {
            next()
        }
    }
}
