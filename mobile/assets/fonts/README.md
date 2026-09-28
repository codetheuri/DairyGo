# Fonts

Inter (400–800) and Outfit (600, 700) from Google Fonts, bundled so text
renders correctly offline and nothing is downloaded at runtime.

Both are licensed under the SIL Open Font License 1.1
(https://openfontlicense.org). The files are subsets covering Latin and
Latin Extended-A (English and Swahili), general punctuation, currency signs
and arrows, made with:

    pyftsubset <font>.ttf --layout-features='*' \
      --unicodes="U+0000-00FF,U+0100-017F,U+2000-206F,U+20A0-20CF,U+2100-214F,U+2190-21FF,U+2212,U+2022"
