import { Injectable, OnModuleDestroy } from '@nestjs/common'
import Redis from 'ioredis'

@Injectable()
export class RedisService implements OnModuleDestroy {
    private readonly redisClient: Redis | null

    constructor() {
        const redisUrl = process.env.REDIS_URL?.trim()
        this.redisClient = redisUrl ? new Redis(redisUrl) : null
    }

    async tryAcquireSeatLock(seatId: string): Promise<boolean | null> {
        if (!this.redisClient) {
            return null
        }

        const lockKey = this.getSeatKey(seatId)
        const result = await this.redisClient.set(lockKey, '1', 'EX', 30, 'NX')

        return result === 'OK'
    }

    async persistSeatLock(seatId: string): Promise<void> {
        if (!this.redisClient) {
            return
        }

        const lockKey = this.getSeatKey(seatId)
        await this.redisClient.set(lockKey, '1')
    }

    async releaseSeatLock(seatId: string): Promise<void> {
        if (!this.redisClient) {
            return
        }

        const lockKey = this.getSeatKey(seatId)
        await this.redisClient.del(lockKey)
    }

    async onModuleDestroy() {
        if (this.redisClient) {
            await this.redisClient.quit()
        }
    }

    private getSeatKey(seatId: string): string {
        return `seat:${seatId}`
    }
}
