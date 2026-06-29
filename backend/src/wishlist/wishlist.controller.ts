import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  Request,
} from '@nestjs/common';
import { WishlistService } from './wishlist.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('wishlists')
export class WishlistController {
  constructor(private readonly wishlistService: WishlistService) {}

  @Post()
  create(@Request() req: any, @Body() dto: any) {
    return this.wishlistService.create(req.user.sub, dto);
  }

  @Get()
  findAll(@Request() req: any) {
    return this.wishlistService.findAll(req.user.sub);
  }

  @Patch('reorder')
  reorder(@Request() req: any, @Body() items: any[]) {
    return this.wishlistService.reorder(req.user.sub, items);
  }

  @Patch(':id')
  update(@Request() req: any, @Param('id') id: string, @Body() dto: any) {
    return this.wishlistService.update(req.user.sub, +id, dto);
  }

  @Delete(':id')
  remove(@Request() req: any, @Param('id') id: string) {
    return this.wishlistService.remove(req.user.sub, +id);
  }
}
