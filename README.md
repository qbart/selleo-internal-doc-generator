# Script used for generating internal docs

## Deps

1. `wkhtmltopdf` binary in your `PATH`
2. `ruby >= 2.3.1`

## Prepartion

1. Download your "protokol" docs from gdrive as html zipped.
2. Unpack html from zip.
3. Adjust your html template with variables:
   * {{NET_INCOME}}
   * {{BEGIN_DATE}}
   * {{END_DATE}}
   * {{LIST}}
4. Fix styling issues for template.
5. Copy template to main folder as `protokol.html`.

## Usage

```
ruby selleo.rb NET_INCOME
```

Then you will be asked to provide tasks on the project.
After confirmation PDF will be generated with dates set automatically to previous month.
