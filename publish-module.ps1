<#
    .SYNOPSIS
    Publish a new version of a PowerShell module to PowerShell Gallery
    .DESCRIPTION
    The script is used to publish a new version of a PowerShell module to PowerShell
    Gallery. It is intended to be executed when running the related GitHub action
    workflow (.github\workflows\publish-module.yml). The required environment variables
    are configured and piped when running the workflow.
#>

Publish-Module -Path $(Join-Path -Path $PSScriptRoot -ChildPath $ENV:ModuleName) -NuGetApiKey $ENV:NuGetApiKey