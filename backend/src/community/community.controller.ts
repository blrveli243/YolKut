import { Controller, Get, Post, Delete, Body, Param, UseGuards, Request, ParseIntPipe } from '@nestjs/common';
import { CommunityService } from './community.service';
import { CreatePostDto, CreateMessageDto, CreateCommentDto } from './dto/community.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('community')
export class CommunityController {
  constructor(private readonly communityService: CommunityService) {}

  @Get('users')
  getUsers(@Request() req: any) {
    return this.communityService.getUsers(req.user.sub);
  }

  @Get('conversations')
  getConversations(@Request() req: any) {
    return this.communityService.getConversations(req.user.sub);
  }

  @Post('friends/:userId')
  toggleFriendStatus(@Request() req: any, @Param('userId', ParseIntPipe) otherUserId: number) {
    return this.communityService.toggleFriendStatus(req.user.sub, otherUserId);
  }

  @Get('posts')
  getPosts(@Request() req: any) {
    return this.communityService.getPosts(req.user.sub);
  }

  @Post('posts')
  createPost(@Request() req: any, @Body() dto: CreatePostDto) {
    return this.communityService.createPost(req.user.sub, dto);
  }

  @Delete('posts/:id')
  deletePost(@Request() req: any, @Param('id', ParseIntPipe) postId: number) {
    return this.communityService.deletePost(req.user.sub, postId);
  }

  @Get('posts/:id/comments')
  getComments(@Param('id', ParseIntPipe) postId: number) {
    return this.communityService.getComments(postId);
  }

  @Post('posts/:id/comments')
  createComment(
    @Request() req: any,
    @Param('id', ParseIntPipe) postId: number,
    @Body() dto: CreateCommentDto,
  ) {
    return this.communityService.createComment(req.user.sub, postId, dto.content);
  }

  @Post('posts/:id/like')
  toggleLike(@Request() req: any, @Param('id', ParseIntPipe) postId: number) {
    return this.communityService.toggleLike(req.user.sub, postId);
  }

  @Get('messages/:userId')
  getMessages(@Request() req: any, @Param('userId', ParseIntPipe) otherUserId: number) {
    return this.communityService.getMessages(req.user.sub, otherUserId);
  }

  @Post('messages/:userId')
  sendMessage(
    @Request() req: any,
    @Param('userId', ParseIntPipe) receiverId: number,
    @Body() dto: CreateMessageDto,
  ) {
    return this.communityService.sendMessage(req.user.sub, receiverId, dto);
  }
}
