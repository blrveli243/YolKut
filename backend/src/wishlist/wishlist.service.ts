import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class WishlistService {
  constructor(private prisma: PrismaService) {}

  async create(userId: number, dto: any) {
    return this.prisma.wishlistItem.create({
      data: {
        userId,
        title: dto.title,
        price: dto.price ? parseFloat(dto.price.toString()) : null,
        link: dto.link,
        orderIndex: dto.orderIndex ?? 0,
      },
    });
  }

  async findAll(userId: number) {
    return this.prisma.wishlistItem.findMany({
      where: { userId },
      orderBy: { orderIndex: 'asc' },
    });
  }

  async update(userId: number, id: number, dto: any) {
    const item = await this.prisma.wishlistItem.findUnique({ where: { id } });
    if (!item) throw new NotFoundException('Item not found');
    if (item.userId !== userId) throw new ForbiddenException('Access denied');

    const updateData: any = {};
    if (dto.title !== undefined) updateData.title = dto.title;
    if (dto.price !== undefined) updateData.price = dto.price ? parseFloat(dto.price.toString()) : null;
    if (dto.link !== undefined) updateData.link = dto.link;
    if (dto.isPurchased !== undefined) updateData.isPurchased = dto.isPurchased;
    if (dto.orderIndex !== undefined) updateData.orderIndex = dto.orderIndex;

    return this.prisma.wishlistItem.update({
      where: { id },
      data: updateData,
    });
  }

  async reorder(userId: number, items: { id: number; orderIndex: number }[]) {
    // In a real app, you might want to do this in a transaction
    for (const item of items) {
      await this.prisma.wishlistItem.updateMany({
        where: { id: item.id, userId },
        data: { orderIndex: item.orderIndex },
      });
    }
    return { success: true };
  }

  async remove(userId: number, id: number) {
    const item = await this.prisma.wishlistItem.findUnique({ where: { id } });
    if (!item) throw new NotFoundException('Item not found');
    if (item.userId !== userId) throw new ForbiddenException('Access denied');

    return this.prisma.wishlistItem.delete({
      where: { id },
    });
  }
}
