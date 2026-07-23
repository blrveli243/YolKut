import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { HealthDataModule } from './health-data/health-data.module';
import { TasksModule } from './tasks/tasks.module';
import { GoalsModule } from './goals/goals.module';
import { ServeStaticModule } from '@nestjs/serve-static';
import { join } from 'path';

import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { NutritionModule } from './nutrition/nutrition.module';
import { WishlistModule } from './wishlist/wishlist.module';
import { ProgramsModule } from './programs/programs.module';
import { RunsModule } from './runs/runs.module';
import { CommunityModule } from './community/community.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ServeStaticModule.forRoot({
      rootPath: join(__dirname, '..', 'uploads'),
      serveRoot: '/uploads',
    }),
    PrismaModule,
    HealthDataModule,
    TasksModule,
    GoalsModule,
    AuthModule,
    UsersModule,
    NutritionModule,
    WishlistModule,
    ProgramsModule,
    RunsModule,
    CommunityModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
