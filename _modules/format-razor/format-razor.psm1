# Copyright 2007 - 2016 Danny Tuppeny (DanTup)

function Format-Razor()
{
    <#
    .SYNOPSIS
        Formats a set of objects using the Razor Engine.
    .DESCRIPTION
        The Format-Razor function formats a set of objects using a supplied template using the Razor Engine created for ASP.NET.
    .NOTES
        Author: Danny Tuppeny (DanTup)
    .LINK
        http://code.dantup.com/PSRazor
    .PARAMETER templateText
        The Razor template text to be processed for each object.
    .PARAMETER modelName
        The name to use for access the data object in the template. Defaults to "Model".
    .EXAMPLE
        Get-Command | Select -Last 10 | Format-Razor "Command name: @Model.Name       Loop: @for (int i = 0; i < 5; i++) { <y>@i</y> }"
    .EXAMPLE
        Get-Command | Select -Last 10 | Format-Razor "Command name: @Data.Name (@Data.CommandType)" -modelName "Data"
    .EXAMPLE
        Format-Razor "Command name: @Peter.Name       Loop: @for (int i = 0; i < 5; i++) { <y>@i</y> }" $host -modelName "Peter"
    #>
    [CmdletBinding()]
    PARAM(
        [Parameter(Mandatory=$true)] [string] $templateText,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)] [PSObject] $model,
        [Parameter(Mandatory=$false)] [string] $modelName = "Model"
    )
    BEGIN
    {
        # Load the MVC assembly so we can access the Razor classes
        [System.Reflection.Assembly]::LoadWithPartialName("System.Web.Razor") | Out-Null

        # Create a StringReader for the template, which we'll need to pass into the Razor Engine
        $stringReader = New-Object System.IO.StringReader($templateText)
        $engine = CreateRazorTemplateEngine
        $razorResult = $engine.GenerateCode($stringReader)
        $results = CompileCode($razorResult);

        # If the template doesn't compile, we can't continue
        if ($results.Errors.HasErrors)
        {
            throw $results.Errors
        }

        # Create an instance of the Razor-generated template class that will be used in PROCESS for formatting
        $template = CreateTemplateInstance($results)
    }

    PROCESS
    {
        # Set the model to the current object, using the $modelName param so the user can customise it
        $template.$modelName = $model

        # Execute the code, which writes the output to our buffer
        $template.Execute()

        # "Return" the output for this item
        $template.Buffer.ToString()

        # Clear the buffer ready for the next object
        $template.Buffer.Clear() | Out-Null
    }
}
# Export the fuction for use by the user
Export-ModuleMember -Function Format-Razor

function CreateRazorTemplateEngine()
{
    # Create an instance of the Razor engine for C#
    $language = New-Object System.Web.Razor.CSharpRazorCodeLanguage
    $host = New-Object System.Web.Razor.RazorEngineHost($language)

    # Set some default properties for the Razor-generated class
    $host.DefaultBaseClass = "TemplateBase" # This is our base class (created below)
    $host.DefaultNamespace = "RazorOutput"
    $host.DefaultClassName = "Template"

    # Add any default namespaces that will be useful to use in the templates
    $host.NamespaceImports.Add("System") | Out-Null

    New-Object System.Web.Razor.RazorTemplateEngine($host)
}

function CompileCode($razorResult)
{
# HACK: To avoid shipping a DLL, we're going to just compile our TemplateBase class here
$baseClass = @"
using System.IO;
using System.Text;

    public abstract class TemplateBase
    {
        public StringBuilder Buffer { get; set; }
        public StringWriter Writer { get; set; }
        public dynamic $modelName { get; set; }

        public TemplateBase()
        {
            this.Buffer = new StringBuilder();
            this.Writer = new StringWriter(this.Buffer);
        }

        public abstract void Execute();

        public virtual void Write(object value)
        {
            WriteLiteral(value);
        }

        public virtual void WriteLiteral(object value)
        {
            Buffer.Append(value);
        }
    }
"@

    # Set up the compiler params, including any references required for the compilation
    $codeProvider = New-Object Microsoft.CSharp.CSharpCodeProvider
    $assemblies = @(
        [System.Reflection.Assembly]::LoadWithPartialName("System.Core").CodeBase.Replace("file:///", ""),
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.CSharp").CodeBase.Replace("file:///", "")
    )    
    $compilerParams = New-Object System.CodeDom.Compiler.CompilerParameters(,$assemblies)

    # Compile the template base class    
    $templateBaseResults = $codeProvider.CompileAssemblyFromSource($compilerParams, $baseClass);

    # Add the (just-generated) template base assembly to the compile parameters
    $assemblies = $assemblies + $templateBaseResults.CompiledAssembly.CodeBase.Replace("file:///", "")
    $compilerParams = New-Object System.CodeDom.Compiler.CompilerParameters(,$assemblies)

    # Compile the Razor-generated code
    $codeProvider.CompileAssemblyFromDom($compilerParams, $razorResult.GeneratedCode)
}

function CreateTemplateInstance($results)
{
    # Grab the assembly that contains the Razor-generated classes
    $assembly = $results.CompiledAssembly

    # Create an instance of our Razor-generated class (this name is hard-coded above)
    $type = $assembly.GetType("RazorOutput.Template")
    [System.Activator]::CreateInstance($type)
}