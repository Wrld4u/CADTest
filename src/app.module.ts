import { Module } from '@nestjs/common'
import { ConfigModule } from '@nestjs/config'
import { PrismaModule } from './infrastructure/prisma/prisma.module'
import { ReservationsModule } from './modules/reservations/infrastructure/reservations.module'

@Module({
    imports: [ConfigModule.forRoot({ isGlobal: true }), PrismaModule, ReservationsModule]
})
export class AppModule {}
