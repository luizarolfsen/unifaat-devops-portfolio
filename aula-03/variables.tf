variable "project_name" {
  type        = string
  description = "Nome do projeto"
  default     = "TechNova"
}

variable "environment" {
  type        = string
  description = "Ambiente de deployment (ex: lab, dev, prod)"
  default     = "lab"
}

variable "aluno" {
  type        = string
  description = "Nome completo do aluno responsável pelo exercício"

  validation {
    condition     = length(var.aluno) > 0
    error_message = "A variável 'aluno' não pode ser vazia."
  }
}

variable "ra" {
  type        = string
  description = "Registro Acadêmico (RA) do aluno"

  validation {
    condition     = length(var.ra) > 0
    error_message = "A variável 'ra' não pode ser vazia."
  }
}
