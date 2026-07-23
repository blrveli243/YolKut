import { Injectable, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { Pool, neonConfig } from '@neondatabase/serverless';
import { PrismaNeon } from '@prisma/adapter-neon';
import ws from 'ws';

neonConfig.webSocketConstructor = ws as any;

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  constructor() {
    const connectionString = process.env.DATABASE_URL;
    const pool = new Pool({ connectionString });
    pool.on('error', (err) => {
      console.error('Neon Pool Error (Socket Hang Up vs):', err.message);
    });
    const adapter = new PrismaNeon(pool) as any;
    super({ adapter });
  }

  async onModuleInit() {
    await this.$connect();
  }
}
