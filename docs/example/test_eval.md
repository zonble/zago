```logo
NL
REPEAT 10 [BOX :# MOVE UP MOVE UP]
```

```logo
NL
TABLE 2 2
```

```logo
NL
REPEAT 10 [TYPE "- " TYPE :# NL]
```

```logo
NL
PD
REPEAT 10 [FD 2 IFELSE :# % 2 == 0 [LEFT][RIGHT]]
```

```logo
PU
PD
FD 10
```


