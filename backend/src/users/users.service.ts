import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async getProfile(userId: number) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        height: true,
        weight: true,
        age: true,
        gender: true,
        dailyGoal: true,
        firstName: true,
        lastName: true,
        photoUrl: true,
        activityLevel: true,
        targetWeight: true,
        targetDays: true,
      },
    });

    if (!user) throw new NotFoundException('Kullanıcı bulunamadı');
    return user;
  }

  async updateProfile(userId: number, dto: UpdateProfileDto) {
    return this.prisma.user.update({
      where: { id: userId },
      data: dto,
      select: {
        id: true,
        email: true,
        height: true,
        weight: true,
        age: true,
        gender: true,
        dailyGoal: true,
        firstName: true,
        lastName: true,
        photoUrl: true,
        activityLevel: true,
        targetWeight: true,
        targetDays: true,
      },
    });
  }
}
