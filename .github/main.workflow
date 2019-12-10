workflow "on pull request, Dockerfile lint" {
  on = "pull_request"
  resolves = ["Dockerfile lint"]
}

action "Dockerfile lint" {
  uses = "jwr0/dockerfile-linter-action"
  secrets = ["GITHUB_TOKEN"]
  # Optionally, if your Dockerfile is not in the root of your repository,
  # you can specify a DOCKERFILE environment variable with the path to
  # your Dockerfile
  env = {
    DOCKERFILE = "./some/other/directory/Dockerfile"
  }
}
