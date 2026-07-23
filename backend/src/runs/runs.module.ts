import { Module } from '@nestjs/common';
import { RunsService } from './runs.service';
import { RunsController } from './runs.controller';
import { PrismaModule } from '../prisma/prisma.module';

import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [RunsController],
  providers: [RunsService],
})
export class RunsModule {}
