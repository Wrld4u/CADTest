export class SeatAlreadyReservedError extends Error {
    constructor() {
        super('К сожалению место уже забронировано')
        this.name = 'SeatAlreadyReservedError'
    }
}
