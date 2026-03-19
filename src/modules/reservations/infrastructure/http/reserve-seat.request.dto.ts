import { IsNotEmpty, IsString } from 'class-validator'

export class ReserveSeatRequestDto {
    @IsString()
    @IsNotEmpty()
    user_id!: string

    @IsString()
    @IsNotEmpty()
    seat_id!: string
}
