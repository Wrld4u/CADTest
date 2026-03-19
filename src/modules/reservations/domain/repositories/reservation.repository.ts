import { Reservation } from '../entities/reservation.entity'

export interface ReservationRepository {
    reserve(params: { userId: string; seatId: string }): Promise<Reservation>
}
