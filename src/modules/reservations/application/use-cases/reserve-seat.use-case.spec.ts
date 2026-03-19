import { Reservation } from '../../domain/entities/reservation.entity'
import { SeatAlreadyReservedError } from '../../domain/errors/seat-already-reserved.error'
import { ReservationRepository } from '../../domain/repositories/reservation.repository'
import { ReserveSeatCommand } from '../dto/reserve-seat.command'
import { ReserveSeatUseCase } from './reserve-seat.use-case'

describe('ReserveSeatUseCase', () => {
    it('успешно бронирует место', async () => {
        const repository: ReservationRepository = {
            reserve: jest.fn().mockResolvedValue(
                new Reservation('r1', 'u1', 's1', new Date())
            )
        }

        const useCase = new ReserveSeatUseCase(repository)
        const result = await useCase.execute(new ReserveSeatCommand('u1', 's1'))

        expect(result.seatId).toBe('s1')
        expect(repository.reserve).toHaveBeenCalledWith({ userId: 'u1', seatId: 's1' })
    })

    it('пробрасывает конфликт занятого места', async () => {
        const repository: ReservationRepository = {
            reserve: jest.fn().mockRejectedValue(new SeatAlreadyReservedError())
        }

        const useCase = new ReserveSeatUseCase(repository)

        await expect(useCase.execute(new ReserveSeatCommand('u2', 's1'))).rejects.toBeInstanceOf(
            SeatAlreadyReservedError
        )
    })
})
