import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePostDto, CreateMessageDto } from './dto/community.dto';

@Injectable()
export class CommunityService {
  constructor(private prisma: PrismaService) {}

  async getPosts(currentUserId: number) {
    try {
      const posts = await this.prisma.post.findMany({
        orderBy: { createdAt: 'desc' },
        include: {
          user: {
            select: { id: true, firstName: true, lastName: true, photoUrl: true },
          },
          _count: {
            select: { likes: true, comments: true },
          },
          likes: {
            where: { userId: currentUserId },
            select: { id: true },
          },
        },
      });

      return posts.map(post => ({
        ...post,
        isLikedByMe: post.likes.length > 0,
        likes: undefined, // Don't leak the raw likes array to client
      }));
    } catch (e) {
      throw new Error('Prisma error: ' + (e.message || e.toString()));
    }
  }

  async createPost(userId: number, dto: CreatePostDto) {
    return this.prisma.post.create({
      data: {
        userId,
        content: dto.content,
        imageUrl: dto.imageUrl,
      },
      include: {
        user: {
          select: { id: true, firstName: true, lastName: true, photoUrl: true },
        },
        _count: {
          select: { likes: true, comments: true },
        },
      },
    });
  }

  async deletePost(userId: number, postId: number) {
    const post = await this.prisma.post.findUnique({ where: { id: postId } });
    if (!post) throw new NotFoundException('Post not found');
    if (post.userId !== userId) throw new NotFoundException('Unauthorized to delete this post');

    // Delete comments and likes first (or use Cascade if configured, but manual is safer here if not)
    await this.prisma.comment.deleteMany({ where: { postId } });
    await this.prisma.like.deleteMany({ where: { postId } });

    await this.prisma.post.delete({ where: { id: postId } });
    return { success: true };
  }

  async getComments(postId: number) {
    return this.prisma.comment.findMany({
      where: { postId },
      orderBy: { createdAt: 'desc' },
      include: {
        user: { select: { id: true, firstName: true, lastName: true, photoUrl: true } },
      },
    });
  }

  async createComment(userId: number, postId: number, content: string) {
    const post = await this.prisma.post.findUnique({ where: { id: postId } });
    if (!post) throw new NotFoundException('Post not found');

    return this.prisma.comment.create({
      data: {
        userId,
        postId,
        content,
      },
      include: {
        user: { select: { id: true, firstName: true, lastName: true, photoUrl: true } },
      },
    });
  }

  async toggleLike(userId: number, postId: number) {
    const post = await this.prisma.post.findUnique({ where: { id: postId } });
    if (!post) throw new NotFoundException('Post not found');

    const existingLike = await this.prisma.like.findUnique({
      where: { userId_postId: { userId, postId } },
    });

    if (existingLike) {
      await this.prisma.like.delete({
        where: { id: existingLike.id },
      });
      return { liked: false };
    } else {
      await this.prisma.like.create({
        data: { userId, postId },
      });
      return { liked: true };
    }
  }

  async getMessages(userId: number, otherUserId: number) {
    return this.prisma.message.findMany({
      where: {
        OR: [
          { senderId: userId, receiverId: otherUserId },
          { senderId: otherUserId, receiverId: userId },
        ],
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async sendMessage(senderId: number, receiverId: number, dto: CreateMessageDto) {
    if (senderId === receiverId) {
      throw new BadRequestException('Kendine mesaj gönderemezsin');
    }
    return this.prisma.message.create({
      data: {
        senderId,
        receiverId,
        content: dto.content,
      },
    });
  }

  async getConversations(userId: number) {
    const messages = await this.prisma.message.findMany({
      where: {
        OR: [{ senderId: userId }, { receiverId: userId }],
      },
      orderBy: { createdAt: 'desc' },
      include: {
        sender: { select: { id: true, firstName: true, lastName: true, photoUrl: true } },
        receiver: { select: { id: true, firstName: true, lastName: true, photoUrl: true } },
      },
    });

    const uniqueChats = new Map<number, any>();

    for (const msg of messages) {
      const otherUserId = msg.senderId === userId ? msg.receiverId : msg.senderId;
      const otherUser = msg.senderId === userId ? msg.receiver : msg.sender;
      
      if (!uniqueChats.has(otherUserId)) {
        uniqueChats.set(otherUserId, {
          userId: otherUserId,
          user: otherUser,
          lastMessage: msg.content,
          isMine: msg.senderId === userId,
          time: msg.createdAt,
        });
      }
    }

    return Array.from(uniqueChats.values());
  }

  async toggleFriendStatus(requesterId: number, receiverId: number) {
    if (requesterId === receiverId) {
      throw new BadRequestException('Kendi kendine arkadaş olamazsın');
    }

    const existing = await this.prisma.friendship.findFirst({
      where: {
        OR: [
          { requesterId, receiverId },
          { requesterId: receiverId, receiverId: requesterId },
        ],
      },
    });

    if (existing) {
      await this.prisma.friendship.delete({ where: { id: existing.id } });
      return { status: 'none' };
    } else {
      await this.prisma.friendship.create({
        data: { requesterId, receiverId, status: 'accepted' },
      });
      return { status: 'accepted' };
    }
  }

  async getUsers(currentUserId: number) {
    const users = await this.prisma.user.findMany({
      select: {
        id: true,
        firstName: true,
        lastName: true,
        photoUrl: true,
        email: true,
      },
    });

    const friendships = await this.prisma.friendship.findMany({
      where: {
        OR: [{ requesterId: currentUserId }, { receiverId: currentUserId }],
      },
    });

    return users.map(user => {
      const isMe = user.id === currentUserId;
      const friend = friendships.find(
        f => (f.requesterId === user.id || f.receiverId === user.id)
      );
      return {
        ...user,
        friendStatus: isMe ? 'none' : (friend ? friend.status : 'none'),
        isMe,
      };
    });
  }
}
