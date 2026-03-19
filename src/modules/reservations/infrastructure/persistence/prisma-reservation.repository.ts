import { Injectable } from '@nestjs/common'
import { RedisService } from '../../../../infrastructure/redis/redis.service'
import { PrismaService } from '../../../../infrastructure/prisma/prisma.service'
import { Prisma } from '../../../../generated/prisma/client'
import { Reservation } from '../../domain/entities/reservation.entity'
import { SeatAlreadyReservedError } from '../../domain/errors/seat-already-reserved.error'
import { ReservationRepository } from '../../domain/repositories/reservation.repository'

@Injectable()
export class PrismaReservationRepository implements ReservationRepository {
    constructor(
        private readonly prisma: PrismaService,
        private readonly redisService: RedisService
    ) {}

    async reserve(params: { userId: string; seatId: string }): Promise<Reservation> {
        const lockAcquired = await this.redisService.tryAcquireSeatLock(params.seatId)
        if (lockAcquired === false) {
            throw new SeatAlreadyReservedError()
        }

        try {
            const createdReservation = await this.prisma.reservation.create({
                data: {
                    userId: params.userId,
                    seatId: params.seatId
                }
            })

            if (lockAcquired === true) {
                await this.redisService.persistSeatLock(params.seatId)
            }

            return new Reservation(
                createdReservation.id,
                createdReservation.userId,
                createdReservation.seatId,
                createdReservation.createdAt
            )
        } catch (error) {
            if (
                error instanceof Prisma.PrismaClientKnownRequestError &&
                error.code === 'P2002'
            ) {
                if (lockAcquired === true) {
                    await this.redisService.persistSeatLock(params.seatId)
                }

                throw new SeatAlreadyReservedError()
            }

            if (lockAcquired === true) {
                await this.redisService.releaseSeatLock(params.seatId)
            }

            throw error
        }
    }
}
