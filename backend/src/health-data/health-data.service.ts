import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class HealthDataService {
  constructor(private prisma: PrismaService) {}

  async create(data: {
    userId: number;
    steps: number;
    activeCalories: number;
    basalCalories: number;
    sleepMinutes: number;
    date: Date;
  }) {
    return this.prisma.healthData.upsert({
      where: {
        userId_date: {
          userId: data.userId,
          date: data.date,
        },
      },
      update: {
        steps: data.steps,
        activeCalories: data.activeCalories,
        basalCalories: data.basalCalories,
        sleepMinutes: data.sleepMinutes,
      },
      create: data,
    });
  }

  async findAll(userId: number) {
    return this.prisma.healthData.findMany({
      where: { userId },
      orderBy: { date: 'desc' },
    });
  }
}
