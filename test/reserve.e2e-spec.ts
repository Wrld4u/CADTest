import { ConflictException, INestApplication } from '@nestjs/common'
import { Test } from '@nestjs/testing'
import { AppModule } from '../src/app.module'
import { Reservation } from '../src/modules/reservations/domain/entities/reservation.entity'
import { SeatAlreadyReservedError } from '../src/modules/reservations/domain/errors/seat-already-reserved.error'
import { ReservationRepository } from '../src/modules/reservations/domain/repositories/reservation.repository'
import { ReservationsController } from '../src/modules/reservations/infrastructure/http/reservations.controller'
import { RESERVATIONS_REPOSITORY } from '../src/modules/reservations/reservations.constants'

class InMemoryReservationRepository implements ReservationRepository {
    private readonly seats = new Set<string>()

    async reserve(params: { userId: string; seatId: string }): Promise<Reservation> {
        if (this.seats.has(params.seatId)) {
            throw new SeatAlreadyReservedError()
        }

        this.seats.add(params.seatId)

        return new Reservation(
            `${params.userId}-${params.seatId}`,
            params.userId,
            params.seatId,
            new Date()
        )
    }
}

describe('POST /reserve (e2e)', () => {
    let app: INestApplication
    let reservationsController: ReservationsController

    beforeAll(async () => {
        const moduleRef = await Test.createTestingModule({
            imports: [AppModule]
        })
            .overrideProvider(RESERVATIONS_REPOSITORY)
            .useClass(InMemoryReservationRepository)
            .compile()

        app = moduleRef.createNestApplication()
        await app.init()
        reservationsController = moduleRef.get(ReservationsController)
    })

    afterAll(async () => {
        await app.close()
    })

    it('возвращает 201 при успешной брони', async () => {
        const response = await reservationsController.reserve({
            user_id: 'user-1',
            seat_id: 'seat-100'
        })

        expect(response.status).toBe('success')
    })

    it('при конкурентной броне одного места даёт один успех и конфликты', async () => {
        const seatId = 'seat-200'
        const calls = Array.from({ length: 10 }).map((_, index) =>
            reservationsController.reserve({
                user_id: `user-${index + 1}`,
                seat_id: seatId
            })
        )

        const results = await Promise.allSettled(calls)
        const successCount = results.filter(item => item.status === 'fulfilled').length
        const conflictCount = results.filter(item => item.status === 'rejected').length
        const firstRejection = results.find(item => item.status === 'rejected')

        expect(successCount).toBe(1)
        expect(conflictCount).toBe(9)
        expect((firstRejection as PromiseRejectedResult).reason).toBeInstanceOf(ConflictException)
        expect((firstRejection as PromiseRejectedResult).reason.message).toBe(
            'К сожалению место уже забронировано'
        )
    })
})
