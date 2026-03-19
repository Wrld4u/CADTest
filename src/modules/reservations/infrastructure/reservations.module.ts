import { Module } from '@nestjs/common'
import { ReserveSeatUseCase } from '../application/use-cases/reserve-seat.use-case'
import { RESERVATIONS_REPOSITORY } from '../reservations.constants'
import { ReservationsController } from './http/reservations.controller'
import { PrismaReservationRepository } from './persistence/prisma-reservation.repository'

@Module({
    controllers: [ReservationsController],
    providers: [
        {
            provide: RESERVATIONS_REPOSITORY,
            useClass: PrismaReservationRepository
        },
        ReserveSeatUseCase
    ]
})
export class ReservationsModule {}
