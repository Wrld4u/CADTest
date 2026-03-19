import { Body, ConflictException, Controller, HttpCode, Post } from '@nestjs/common'
import { ReserveSeatCommand } from '../../application/dto/reserve-seat.command'
import { ReserveSeatUseCase } from '../../application/use-cases/reserve-seat.use-case'
import { SeatAlreadyReservedError } from '../../domain/errors/seat-already-reserved.error'
import { ReserveSeatRequestDto } from './reserve-seat.request.dto'

@Controller()
export class ReservationsController {
    constructor(private readonly reserveSeatUseCase: ReserveSeatUseCase) {}

    @Post('reserve')
    @HttpCode(201)
    async reserve(@Body() body: ReserveSeatRequestDto) {
        try {
            const reservation = await this.reserveSeatUseCase.execute(
                new ReserveSeatCommand(body.user_id, body.seat_id)
            )

            return {
                status: 'success',
                reservation_id: reservation.id,
                user_id: reservation.userId,
                seat_id: reservation.seatId
            }
        } catch (error) {
            if (error instanceof SeatAlreadyReservedError) {
                throw new ConflictException(error.message)
            }

            throw error
        }
    }
}
