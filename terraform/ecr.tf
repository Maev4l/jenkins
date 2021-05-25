resource "aws_ecr_repository" "image_resize_repository" {
  name                 = "jenkins"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "image_common_repository_lifecycle" {
  repository = aws_ecr_repository.image_resize_repository.name
  policy     = file("ecr-lifecycle-policy.json")
}
