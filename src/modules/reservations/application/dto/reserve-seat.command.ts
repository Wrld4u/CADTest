export class ReserveSeatCommand {
    constructor(
        public readonly userId: string,
        public readonly seatId: string
    ) {}
}
