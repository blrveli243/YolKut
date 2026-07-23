import { IsString, IsOptional } from 'class-validator';

export class CreatePostDto {
  @IsString()
  content: string;

  @IsOptional()
  @IsString()
  imageUrl?: string;
}

export class CreateMessageDto {
  @IsString()
  content: string;
}

export class CreateCommentDto {
  @IsString()
  content: string;
}
