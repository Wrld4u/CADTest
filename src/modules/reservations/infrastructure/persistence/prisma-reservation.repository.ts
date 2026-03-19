import { Injectable } from '@nestjs/common'
import { PrismaService } from '../../../../infrastructure/prisma/prisma.service'
import { Prisma } from '../../../../generated/prisma/client'
import { Reservation } from '../../domain/entities/reservation.entity'
import { SeatAlreadyReservedError } from '../../domain/errors/seat-already-reserved.error'
import { ReservationRepository } from '../../domain/repositories/reservation.repository'

@Injectable()
export class PrismaReservationRepository implements ReservationRepository {
    constructor(private readonly prisma: PrismaService) {}

    async reserve(params: { userId: string; seatId: string }): Promise<Reservation> {
        try {
            const createdReservation = await this.prisma.reservation.create({
                data: {
                    userId: params.userId,
                    seatId: params.seatId
                }
            })

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
                throw new SeatAlreadyReservedError()
            }

            throw error
        }
    }
}
