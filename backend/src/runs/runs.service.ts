import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateRunDto } from './dto/create-run.dto';

@Injectable()
export class RunsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: number, dto: CreateRunDto) {
    return this.prisma.runSession.create({
      data: {
        userId,
        distanceKm: dto.distanceKm,
        elapsedSeconds: dto.elapsedSeconds,
        targetSpeedKmH: dto.targetSpeedKmH,
        averageSpeedKmH: dto.averageSpeedKmH,
        date: dto.date ? new Date(dto.date) : new Date(),
      },
    });
  }

  async findAllByUser(userId: number) {
    return this.prisma.runSession.findMany({
      where: { userId },
      orderBy: { date: 'desc' },
    });
  }
}
