import { Controller, Post, Body, Get, UseGuards, Request } from '@nestjs/common';
import { RunsService } from './runs.service';
import { CreateRunDto } from './dto/create-run.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('runs')
export class RunsController {
  constructor(private readonly runsService: RunsService) {}

  @Post()
  create(@Request() req: any, @Body() dto: CreateRunDto) {
    return this.runsService.create(req.user.sub, dto);
  }

  @Get()
  findAll(@Request() req: any) {
    return this.runsService.findAllByUser(req.user.sub);
  }
}
