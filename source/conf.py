import sphinx_rtd_theme

project = 'grubY'
copyright = '2026, Sreyanshu'
author = 'Sreyanshu'

extensions = [
    'myst_parser',
    'sphinx_rtd_theme',
]

html_theme = 'sphinx_rtd_theme'
html_theme_options = {
    'display_version': False,
    'prev_next_buttons_location': 'bottom',
}
html_show_sphinx = False
html_show_sourcelink = False
