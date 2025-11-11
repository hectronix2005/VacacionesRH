# Pagy initializer file (8.6.3)
# https://ddnexus.github.io/pagy/docs/how-to#global-configuration

# Instance variables
# Pagy::DEFAULT[:page]   = 1                                  # default page to show
# Pagy::DEFAULT[:items]  = 20                                 # default items per page
# Pagy::DEFAULT[:outset] = 0                                  # default outset extra items before the current page

# Other Variables
# Pagy::DEFAULT[:size]       = 5                              # Nav bar size
# Pagy::DEFAULT[:page_param] = :page                          # Override the default :page param name
# Pagy::DEFAULT[:params]     = {}                             # Hash of extra params for :url method
# Pagy::DEFAULT[:fragment]   = '#fragment'                    # Jump to anchor fragment string
# Pagy::DEFAULT[:link_extra] = 'data-remote="true"'          # Html attributes added to page links
# Pagy::DEFAULT[:i18n_key]   = 'pagy.item_name'              # I18n key

# Enable overflow extra to handle edge cases
require 'pagy/extras/overflow'
Pagy::DEFAULT[:overflow] = :last_page                         # Handle overflow by redirecting to last page

# Enable support for collections
require 'pagy/extras/array'                                   # Enable array support

# Pagy I18n
# Load the "de" built-in locale
# Pagy::I18n.load(locale: 'de')

# Load the "en" built-in locale plus a custom "es" locale
# Pagy::I18n.load({ locale: 'en' }, { locale: 'es', filepath: 'path/to/es.yml' })

# Spanish locale configuration
Pagy::I18n.load(locale: 'es')

# Customize for this application
Pagy::DEFAULT[:items] = 10                                    # default items per page
Pagy::DEFAULT[:size]  = 7                                     # Nav bar size