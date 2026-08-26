# Useful Procedures

```logo
TO TOHANGUL :str op TRANSLIT "Any-Hangul" :str END
TO TOTHAI :str op TRANSLIT "Any-Thai" :str END
TO TOGREEK :str op TRANSLIT "Any-Greek" :str END
TO TOCYRILLIC :str op TRANSLIT "Any-Cyrillic" :str END
TO TOARABIC :str op TRANSLIT "Any-Arabic" :str END
TO TOHEBREW :str op TRANSLIT "Any-Hebrew" :str END
TO TODEVANNAGARI :str op TRANSLIT "Any-Devanagari" :str END
TO TOTAMIL :str op TRANSLIT "Any-Tamil" :str END
TO TOTELUGU :str op TRANSLIT "Any-Telugu" :str END
TO TOBENGALI :str op TRANSLIT "Any-Bengali" :str END
TO TOGEOGIAN :str op TRANSLIT "Any-Georgian" :str END
```

```logo
TO CDATE DATE roc zh_TW END
TO CNUMBER :amout FORMAT.NUMBER :amout "spellout zh_TW END
TO CMONEY :amout FORMAT.NUMBER :amout "bank zh-TW END

TO SLUG :title  OP LOWERCASE REGEX.REPLACE "\s+" "-" (TRIM :title) END
```

```logo
TO STEPCARD :text
  NL BOX 24 3 :text "center "Single round SE NL
  TYPE "           ↓ " NL
END
```

```logo
TO YES type "✅ END
TO NO type "❌ END
```

YES ✅

