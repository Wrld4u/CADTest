export class Reservation {
    constructor(
        public readonly id: string,
        public readonly userId: string,
        public readonly seatId: string,
        public readonly createdAt: Date
    ) {}
}
