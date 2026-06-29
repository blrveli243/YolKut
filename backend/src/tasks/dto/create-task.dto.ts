import { IsString, IsNotEmpty, IsDateString, IsOptional } from 'class-validator';

export class CreateTaskDto {
  @IsString()
  @IsNotEmpty()
  title: string;

  @IsDateString()
  date: string;

  @IsOptional()
  @IsDateString()
  scheduledTime?: string;

  @IsOptional()
  @IsString()
  location?: string;
}
