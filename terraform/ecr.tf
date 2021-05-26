
resource "aws_ecr_repository" "image_jenkins_repository" {
  name                 = "jenkins"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "image_jenkins_repository_lifecycle" {
  repository = aws_ecr_repository.image_jenkins_repository.name
  policy     = file("ecr-lifecycle-policy.json")
}

resource "aws_ecr_repository" "image_jenkins_python_repository" {
  name                 = "jenkins/python"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "image_jenkins_python_repository_lifecycle" {
  repository = aws_ecr_repository.image_jenkins_python_repository.name
  policy     = file("ecr-lifecycle-policy.json")
}

resource "aws_ecr_repository" "image_jenkins_nodejs_repository" {
  name                 = "jenkins/nodejs"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "image_jenkins_nodejs_repository_lifecyle" {
  repository = aws_ecr_repository.image_jenkins_nodejs_repository.name
  policy     = file("ecr-lifecycle-policy.json")
}

