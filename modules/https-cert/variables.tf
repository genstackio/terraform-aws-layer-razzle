variable "dns" {
  type = string
}
variable "zone" {
  type = string
}
variable "apex_redirect" {
  type    = bool
  default = false
}