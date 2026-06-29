import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateGoalDto } from './dto/create-goal.dto';

@Injectable()
export class GoalsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: number, dto: CreateGoalDto) {
    const goal = await this.prisma.goal.create({
      data: {
        userId,
        title: dto.title,
        category: dto.category,
        targetDays: dto.targetDays,
      },
    });

    const tasksToCreate = [];
    let currentDate = new Date();
    currentDate.setUTCHours(0,0,0,0);
    
    for (let i = 0; i < dto.targetDays; i++) {
      const date = new Date(currentDate);
      date.setDate(date.getDate() + i);
      
      let dayOfWeek = date.getDay();
      if (dayOfWeek === 0) dayOfWeek = 7; // Sunday=7
      
      if (dto.daysOfWeek.includes(dayOfWeek)) {
        tasksToCreate.push({
          userId,
          goalId: goal.id,
          title: dto.taskTitle,
          date: date,
        });
      }
    }

    if (tasksToCreate.length > 0) {
      await this.prisma.task.createMany({
        data: tasksToCreate,
      });
    }

    return goal;
  }

  async findAll(userId: number) {
    return this.prisma.goal.findMany({
      where: { userId },
      include: {
        tasks: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}
