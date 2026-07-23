import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTaskDto } from './dto/create-task.dto';
import { UpdateTaskDto } from './dto/update-task.dto';

@Injectable()
export class TasksService {
  constructor(private prisma: PrismaService) {}

  async create(userId: number, dto: CreateTaskDto) {
    return this.prisma.task.create({
      data: {
        userId,
        title: dto.title,
        date: new Date(dto.date),
        scheduledTime: dto.scheduledTime ? new Date(dto.scheduledTime) : null,
        location: dto.location,
      },
    });
  }

  async getStats(userId: number, dateStr?: string) {
    // Tüm görevleri getir
    const allTasks = await this.prisma.task.findMany({
      where: { userId },
    });

    const overallTotal = allTasks.length;
    const overallCompleted = allTasks.filter((t: any) => t.isCompleted).length;
    const overallRate =
      overallTotal > 0 ? (overallCompleted / overallTotal) * 100 : 0;

    let dailyRate = 0;
    if (dateStr) {
      const startDate = new Date(dateStr);
      startDate.setUTCHours(0, 0, 0, 0);

      const endDate = new Date(startDate);
      endDate.setDate(endDate.getDate() + 1);

      const dailyTasks = allTasks.filter(
        (t: any) => t.date >= startDate && t.date < endDate,
      );
      const dailyTotal = dailyTasks.length;
      const dailyCompleted = dailyTasks.filter((t: any) => t.isCompleted).length;
      dailyRate = dailyTotal > 0 ? (dailyCompleted / dailyTotal) * 100 : 0;
    }

    return {
      dailyRate: Math.round(dailyRate),
      overallRate: Math.round(overallRate),
      overallTotal,
      overallCompleted,
    };
  }

  async findAll(userId: number, dateStr?: string) {
    const whereClause: any = { userId };

    if (dateStr) {
      const startDate = new Date(dateStr);
      startDate.setUTCHours(0, 0, 0, 0);

      const endDate = new Date(startDate);
      endDate.setDate(endDate.getDate() + 1);

      whereClause.date = {
        gte: startDate,
        lt: endDate,
      };
    }

    return this.prisma.task.findMany({
      where: whereClause,
      include: { goal: true },
      orderBy: { date: 'asc' },
    });
  }

  async update(userId: number, id: number, dto: UpdateTaskDto) {
    const task = await this.prisma.task.findUnique({ where: { id } });
    if (!task) throw new NotFoundException('Görev bulunamadı');
    if (task.userId !== userId)
      throw new ForbiddenException('Erişim reddedildi');

    const updateData: any = {};
    if (dto.title !== undefined) updateData.title = dto.title;
    if (dto.isCompleted !== undefined) updateData.isCompleted = dto.isCompleted;
    if (dto.date !== undefined) updateData.date = new Date(dto.date);
    if (dto.scheduledTime !== undefined)
      updateData.scheduledTime = dto.scheduledTime
        ? new Date(dto.scheduledTime)
        : null;
    if (dto.location !== undefined) updateData.location = dto.location;

    return this.prisma.task.update({
      where: { id },
      data: updateData,
    });
  }

  async remove(userId: number, id: number) {
    const task = await this.prisma.task.findUnique({ where: { id } });
    if (!task) throw new NotFoundException('Görev bulunamadı');
    if (task.userId !== userId)
      throw new ForbiddenException('Erişim reddedildi');

    return this.prisma.task.delete({
      where: { id },
    });
  }
}
