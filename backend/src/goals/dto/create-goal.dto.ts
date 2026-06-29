import { IsString, IsInt, IsArray, IsNotEmpty } from 'class-validator';

export class CreateGoalDto {
  @IsString()
  @IsNotEmpty()
  title: string;

  @IsString()
  @IsNotEmpty()
  category: string;

  @IsInt()
  targetDays: number;

  @IsArray()
  @IsInt({ each: true })
  daysOfWeek: number[];

  @IsString()
  @IsNotEmpty()
  taskTitle: string;
}
