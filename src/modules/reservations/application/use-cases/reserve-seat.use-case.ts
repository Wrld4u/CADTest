import { Inject, Injectable } from '@nestjs/common'
import { RESERVATIONS_REPOSITORY } from '../../reservations.constants'
import { Reservation } from '../../domain/entities/reservation.entity'
import { ReservationRepository } from '../../domain/repositories/reservation.repository'
import { ReserveSeatCommand } from '../dto/reserve-seat.command'

@Injectable()
export class ReserveSeatUseCase {
    constructor(
        @Inject(RESERVATIONS_REPOSITORY)
        private readonly reservationRepository: ReservationRepository
    ) {}

    async execute(command: ReserveSeatCommand): Promise<Reservation> {
        return this.reservationRepository.reserve({
            userId: command.userId,
            seatId: command.seatId
        })
    }
}
