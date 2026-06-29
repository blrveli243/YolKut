import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ProgramsService {
  constructor(private prisma: PrismaService) {}

  // --- Custom Exercises ---
  async getCustomExercises(userId: number) {
    return this.prisma.customExercise.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createCustomExercise(userId: number, name: string, category: string) {
    return this.prisma.customExercise.create({
      data: {
        userId,
        name: name.toString(),
        category: category.toString(),
      },
    });
  }

  // --- Scheduled Exercises (Program) ---
  async getScheduledExercises(userId: number) {
    return this.prisma.scheduledExercise.findMany({
      where: { userId },
      orderBy: [{ weekday: 'asc' }, { createdAt: 'asc' }],
    });
  }

  async addScheduledExercise(userId: number, dto: any) {
    return this.prisma.scheduledExercise.create({
      data: {
        userId,
        weekday: dto.weekday,
        exerciseId: dto.exerciseId,
        targetSets: dto.targetSets,
        targetReps: dto.targetReps,
      },
    });
  }

  async removeScheduledExercise(userId: number, id: number) {
    const exercise = await this.prisma.scheduledExercise.findFirst({
      where: { id, userId },
    });
    if (!exercise) {
      throw new NotFoundException('Exercise not found in your program');
    }
    return this.prisma.scheduledExercise.delete({
      where: { id },
    });
  }
}
