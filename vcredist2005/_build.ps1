# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


New-Package @{
    Version = "8.0.61000" # Msi Product Version (x64)
    FileUrl = @(
        "https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x64.EXE",
        "https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.EXE"
    )
    Checksum = @(
        "sha256:0551a61c85b718e1fa015b0c3e3f4c4eea0637055536c00e7969286b4fa663e0",
        "sha256:4ee4da0fe62d5fa1b5e80c6e6d88a4a2f8b3b140c35da51053d0d7b72a381d29"
    )
}