import Foundation

extension LogoPrimitive {
    var dataMeta: LogoPrimitiveMeta? {
        switch self {
        case .thing:
            LogoPrimitiveMeta(
                name: "THING",
                description: "Returns value of named variable (same as :var).",
                localizedDescriptionKey: "logo.doc.thing",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "varname", required: true)],
                examples: [LogoPrimitiveExample(input: "THING \"count")]
            )

        case .word:
            LogoPrimitiveMeta(
                name: "WORD",
                description: "Concatenates words into a single word string.",
                localizedDescriptionKey: "logo.doc.word",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "word1", required: true),
                    LogoPrimitiveParameter(name: "word2", required: true),
                    LogoPrimitiveParameter(name: "...", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "WORD \"Hello \"World", output: "HelloWorld")]
            )

        case .list:
            LogoPrimitiveMeta(
                name: "LIST",
                description: "Creates a new list from supplied items.",
                localizedDescriptionKey: "logo.doc.list",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "item1", required: true),
                    LogoPrimitiveParameter(name: "item2", required: true),
                    LogoPrimitiveParameter(name: "...", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "LIST 1 2", output: "[1 2]")]
            )

        case .sentence:
            LogoPrimitiveMeta(
                name: "SENTENCE",
                description: "Combines items or list elements into a single flattened list.",
                localizedDescriptionKey: "logo.doc.sentence",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "item1", required: true),
                    LogoPrimitiveParameter(name: "item2", required: true),
                    LogoPrimitiveParameter(name: "...", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "SE [Hello] [World]", output: "[Hello World]")]
            )

        case .fput:
            LogoPrimitiveMeta(
                name: "FPUT",
                description: "Prepends item to the front of list or string.",
                localizedDescriptionKey: "logo.doc.fput",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "item", required: true),
                    LogoPrimitiveParameter(name: "list", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "FPUT 0 [1 2 3]", output: "[0 1 2 3]")]
            )

        case .lput:
            LogoPrimitiveMeta(
                name: "LPUT",
                description: "Appends item to the end of list or string.",
                localizedDescriptionKey: "logo.doc.lput",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "item", required: true),
                    LogoPrimitiveParameter(name: "list", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "LPUT 4 [1 2 3]", output: "[1 2 3 4]")]
            )

        case .array:
            LogoPrimitiveMeta(
                name: "ARRAY",
                description: "Creates fixed-size indexed array.",
                localizedDescriptionKey: "logo.doc.array",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "size", required: true),
                    LogoPrimitiveParameter(name: "origin", required: false)
                ],
                examples: [LogoPrimitiveExample(input: "ARRAY 10")]
            )

        case .mdarray:
            LogoPrimitiveMeta(
                name: "MDARRAY",
                description: "Creates multi-dimensional nested array.",
                localizedDescriptionKey: "logo.doc.mdarray",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "dimensions", required: true)],
                examples: [LogoPrimitiveExample(input: "MDARRAY [3 3]")]
            )

        case .mditem:
            LogoPrimitiveMeta(
                name: "MDITEM",
                description: "Accesses item in multi-dimensional array at indices.",
                localizedDescriptionKey: "logo.doc.mditem",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "indices", required: true),
                    LogoPrimitiveParameter(name: "array", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "MDITEM [1 2] :grid")]
            )

        case .mdsetItem:
            LogoPrimitiveMeta(
                name: "MDSETITEM",
                description: "Sets value in multi-dimensional array at indices.",
                localizedDescriptionKey: "logo.doc.mdsetitem",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "indices", required: true),
                    LogoPrimitiveParameter(name: "array", required: true),
                    LogoPrimitiveParameter(name: "value", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "MDSETITEM [1 2] :grid 99")]
            )

        case .listToArray:
            LogoPrimitiveMeta(
                name: "LISTTOARRAY",
                description: "Converts list to fixed-size array.",
                localizedDescriptionKey: "logo.doc.listtoarray",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "list", required: true)],
                examples: [LogoPrimitiveExample(input: "LISTTOARRAY [A B C]")]
            )

        case .arrayToList:
            LogoPrimitiveMeta(
                name: "ARRAYTOLIST",
                description: "Converts array to list.",
                localizedDescriptionKey: "logo.doc.arraytolist",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "array", required: true)],
                examples: [LogoPrimitiveExample(input: "ARRAYTOLIST :myArr")]
            )

        case .combine:
            LogoPrimitiveMeta(
                name: "COMBINE",
                description: "Combines item with data (prepends or appends based on type).",
                localizedDescriptionKey: "logo.doc.combine",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "item", required: true),
                    LogoPrimitiveParameter(name: "data", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "COMBINE \"A [B C]", output: "[A B C]")]
            )

        case .reverse:
            LogoPrimitiveMeta(
                name: "REVERSE",
                description: "Reverses items in list, array, or characters in word.",
                localizedDescriptionKey: "logo.doc.reverse",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "data", required: true)],
                examples: [LogoPrimitiveExample(input: "REVERSE [1 2 3]", output: "[3 2 1]")]
            )

        case .gensym:
            LogoPrimitiveMeta(
                name: "GENSYM",
                description: "Generates unique symbol name (e.g. G1, G2).",
                localizedDescriptionKey: "logo.doc.gensym",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "MAKE \"sym GENSYM")]
            )

        case .first:
            LogoPrimitiveMeta(
                name: "FIRST",
                description: "Returns first element of list or first character of word.",
                localizedDescriptionKey: "logo.doc.first",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "data", required: true)],
                examples: [LogoPrimitiveExample(input: "FIRST [Apple Banana]", output: "Apple")]
            )

        case .last:
            LogoPrimitiveMeta(
                name: "LAST",
                description: "Returns last element of list or last character of word.",
                localizedDescriptionKey: "logo.doc.last",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "data", required: true)],
                examples: [LogoPrimitiveExample(input: "LAST [Apple Banana]", output: "Banana")]
            )

        case .firsts:
            LogoPrimitiveMeta(
                name: "FIRSTS",
                description: "Returns list containing first element of each sublist.",
                localizedDescriptionKey: "logo.doc.firsts",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "listOfLists", required: true)],
                examples: [LogoPrimitiveExample(input: "FIRSTS [[A 1] [B 2]]", output: "[A B]")]
            )

        case .butFirst:
            LogoPrimitiveMeta(
                name: "BUTFIRST",
                description: "Returns list or word without its first element.",
                localizedDescriptionKey: "logo.doc.butfirst",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "data", required: true)],
                examples: [LogoPrimitiveExample(input: "BF [A B C]", output: "[B C]")]
            )

        case .butLast:
            LogoPrimitiveMeta(
                name: "BUTLAST",
                description: "Returns list or word without its last element.",
                localizedDescriptionKey: "logo.doc.butlast",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "data", required: true)],
                examples: [LogoPrimitiveExample(input: "BL [A B C]", output: "[A B]")]
            )

        case .butFirsts:
            LogoPrimitiveMeta(
                name: "BUTFIRSTS",
                description: "Returns list of sublists without their first elements.",
                localizedDescriptionKey: "logo.doc.butfirsts",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "listOfLists", required: true)],
                examples: [LogoPrimitiveExample(input: "BFS [[A 1] [B 2]]", output: "[[1] [2]]")]
            )

        case .item:
            LogoPrimitiveMeta(
                name: "ITEM",
                description: "Returns 1-based nth element of list, array, or word.",
                localizedDescriptionKey: "logo.doc.item",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "index", required: true),
                    LogoPrimitiveParameter(name: "data", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "ITEM 2 [Apple Banana Orange]", output: "Banana")]
            )

        case .pick:
            LogoPrimitiveMeta(
                name: "PICK",
                description: "Randomly selects an element from list, array, or word.",
                localizedDescriptionKey: "logo.doc.pick",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "data", required: true)],
                examples: [LogoPrimitiveExample(input: "PICK [Heads Tails]")]
            )

        case .remove:
            LogoPrimitiveMeta(
                name: "REMOVE",
                description: "Removes all occurrences of item from list or word.",
                localizedDescriptionKey: "logo.doc.remove",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "item", required: true),
                    LogoPrimitiveParameter(name: "data", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "REMOVE 2 [1 2 3 2 4]", output: "[1 3 4]")]
            )

        case .remdup:
            LogoPrimitiveMeta(
                name: "REMDUP",
                description: "Removes duplicate elements from list or word preserving first order.",
                localizedDescriptionKey: "logo.doc.remdup",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "data", required: true)],
                examples: [LogoPrimitiveExample(input: "REMDUP [1 2 2 3 1]", output: "[1 2 3]")]
            )

        case .quoted:
            LogoPrimitiveMeta(
                name: "QUOTED",
                description: "Wraps word with leading double-quote literal.",
                localizedDescriptionKey: "logo.doc.quoted",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "word", required: true)],
                examples: [LogoPrimitiveExample(input: "QUOTED \"test", output: "\"test")]
            )

        case .split:
            LogoPrimitiveMeta(
                name: "SPLIT",
                description: "Splits string by delimiter into list of tokens.",
                localizedDescriptionKey: "logo.doc.split",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "string", required: true),
                    LogoPrimitiveParameter(name: "separator", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "SPLIT \"a,b,c \",", output: "[a b c]")]
            )

        case .setItem:
            LogoPrimitiveMeta(
                name: "SETITEM",
                description: "Mutates element at index in array.",
                localizedDescriptionKey: "logo.doc.setitem",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "index", required: true),
                    LogoPrimitiveParameter(name: "array", required: true),
                    LogoPrimitiveParameter(name: "value", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "SETITEM 1 :arr \"New")]
            )

        case .setFirst:
            LogoPrimitiveMeta(
                name: "SETFIRST",
                description: "Mutates first element of list in-place.",
                localizedDescriptionKey: "logo.doc.setfirst",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "list", required: true),
                    LogoPrimitiveParameter(name: "value", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "SETFIRST :myList 99")]
            )

        case .setBFL:
            LogoPrimitiveMeta(
                name: "SETBUTFIRST",
                description: "Mutates butfirst rest of list in-place.",
                localizedDescriptionKey: "logo.doc.setbutfirst",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "list", required: true),
                    LogoPrimitiveParameter(name: "newRest", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "SETBUTFIRST :myList [X Y]")]
            )

        case .push:
            LogoPrimitiveMeta(
                name: "PUSH",
                description: "Pushes item onto variable stack list.",
                localizedDescriptionKey: "logo.doc.push",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "stackVar", required: true),
                    LogoPrimitiveParameter(name: "item", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "PUSH \"stack 42")]
            )

        case .pop:
            LogoPrimitiveMeta(
                name: "POP",
                description: "Pops and returns top item from variable stack list.",
                localizedDescriptionKey: "logo.doc.pop",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "stackVar", required: true)],
                examples: [LogoPrimitiveExample(input: "MAKE \"top POP \"stack")]
            )

        case .dequeue:
            LogoPrimitiveMeta(
                name: "DEQUEUE",
                description: "Dequeues and returns front item from variable queue list.",
                localizedDescriptionKey: "logo.doc.dequeue",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "queueVar", required: true)],
                examples: [LogoPrimitiveExample(input: "MAKE \"item DEQUEUE \"q")]
            )

        case .pprop:
            LogoPrimitiveMeta(
                name: "PPROP",
                description: "Puts property key-value pair into property list.",
                localizedDescriptionKey: "logo.doc.pprop",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "plistName", required: true),
                    LogoPrimitiveParameter(name: "propName", required: true),
                    LogoPrimitiveParameter(name: "value", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "PPROP \"person \"age 30")]
            )

        case .gprop:
            LogoPrimitiveMeta(
                name: "GPROP",
                description: "Gets property value from property list.",
                localizedDescriptionKey: "logo.doc.gprop",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "plistName", required: true),
                    LogoPrimitiveParameter(name: "propName", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "GPROP \"person \"age", output: "30")]
            )

        case .remprop:
            LogoPrimitiveMeta(
                name: "REMPROP",
                description: "Removes property from property list.",
                localizedDescriptionKey: "logo.doc.remprop",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "plistName", required: true),
                    LogoPrimitiveParameter(name: "propName", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "REMPROP \"person \"age")]
            )

        case .plist:
            LogoPrimitiveMeta(
                name: "PLIST",
                description: "Returns alternating key-value list for named property list.",
                localizedDescriptionKey: "logo.doc.plist",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "plistName", required: true)],
                examples: [LogoPrimitiveExample(input: "PLIST \"person")]
            )

        case .plists:
            LogoPrimitiveMeta(
                name: "PLISTS",
                description: "Returns list of all active property list names.",
                localizedDescriptionKey: "logo.doc.plists",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "PLISTS")]
            )

        case .error:
            LogoPrimitiveMeta(
                name: "ERROR",
                description: "Returns list describing last uncaught error [code message proc].",
                localizedDescriptionKey: "logo.doc.error",
                source: .ucbLogo,
                examples: [LogoPrimitiveExample(input: "ERROR")]
            )

        case .isWord:
            LogoPrimitiveMeta(
                name: "WORD?",
                description: "Tests whether value is a word/string.",
                localizedDescriptionKey: "logo.doc.isword",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "value", required: true)],
                examples: [LogoPrimitiveExample(input: "WORD? \"hello", output: "true")]
            )

        case .isList:
            LogoPrimitiveMeta(
                name: "LIST?",
                description: "Tests whether value is a list.",
                localizedDescriptionKey: "logo.doc.islist",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "value", required: true)],
                examples: [LogoPrimitiveExample(input: "LIST? [1 2]", output: "true")]
            )

        case .isArray:
            LogoPrimitiveMeta(
                name: "ARRAY?",
                description: "Tests whether value is an array.",
                localizedDescriptionKey: "logo.doc.isarray",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "value", required: true)],
                examples: [LogoPrimitiveExample(input: "ARRAY? :arr")]
            )

        case .isNumber:
            LogoPrimitiveMeta(
                name: "NUMBER?",
                description: "Tests whether value is a valid numeric value.",
                localizedDescriptionKey: "logo.doc.isnumber",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "value", required: true)],
                examples: [LogoPrimitiveExample(input: "NUMBER? 42", output: "true")]
            )

        case .isEmpty:
            LogoPrimitiveMeta(
                name: "EMPTY?",
                description: "Tests whether word, list, or array is empty.",
                localizedDescriptionKey: "logo.doc.isempty",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "data", required: true)],
                examples: [LogoPrimitiveExample(input: "EMPTY? []", output: "true")]
            )

        case .isEqual:
            LogoPrimitiveMeta(
                name: "EQUAL?",
                description: "Tests whether two values are equal.",
                localizedDescriptionKey: "logo.doc.isequal",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "EQUAL? 10 10", output: "true")]
            )

        case .isNotEqual:
            LogoPrimitiveMeta(
                name: "NOTEQUAL?",
                description: "Tests whether two values are not equal.",
                localizedDescriptionKey: "logo.doc.isnotequal",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "NOTEQUAL? 1 2", output: "true")]
            )

        case .isIdentityEqual:
            LogoPrimitiveMeta(
                name: ".EQ",
                description: "Tests reference identity equality between arrays or lists.",
                localizedDescriptionKey: "logo.doc.isidentity",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true)
                ],
                examples: [LogoPrimitiveExample(input: ".EQ :a :b")]
            )

        case .isBefore:
            LogoPrimitiveMeta(
                name: "BEFORE?",
                description: "Tests alphabetical ordering of two strings.",
                localizedDescriptionKey: "logo.doc.isbefore",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "a", required: true),
                    LogoPrimitiveParameter(name: "b", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "BEFORE? \"apple \"banana", output: "true")]
            )

        case .isMember:
            LogoPrimitiveMeta(
                name: "MEMBER?",
                description: "Tests whether item is contained in list or word.",
                localizedDescriptionKey: "logo.doc.ismember",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "item", required: true),
                    LogoPrimitiveParameter(name: "data", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "MEMBER? 2 [1 2 3]", output: "true")]
            )

        case .isSubstring:
            LogoPrimitiveMeta(
                name: "SUBSTRING?",
                description: "Tests whether sub is a substring of string.",
                localizedDescriptionKey: "logo.doc.issubstring",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "sub", required: true),
                    LogoPrimitiveParameter(name: "string", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "SUBSTRING? \"log \"logo", output: "true")]
            )

        case .isProcedure:
            LogoPrimitiveMeta(
                name: "PROCEDURE?",
                description: "Tests whether name is a defined custom procedure.",
                localizedDescriptionKey: "logo.doc.isprocedure",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "name", required: true)],
                examples: [LogoPrimitiveExample(input: "PROCEDURE? \"square")]
            )

        case .isPrimitive:
            LogoPrimitiveMeta(
                name: "PRIMITIVE?",
                description: "Tests whether name is a built-in primitive.",
                localizedDescriptionKey: "logo.doc.isprimitive",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "name", required: true)],
                examples: [LogoPrimitiveExample(input: "PRIMITIVE? \"sum", output: "true")]
            )

        case .isDefined:
            LogoPrimitiveMeta(
                name: "DEFINED?",
                description: "Tests whether name is a defined procedure or primitive.",
                localizedDescriptionKey: "logo.doc.isdefined",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "name", required: true)],
                examples: [LogoPrimitiveExample(input: "DEFINED? \"box", output: "true")]
            )

        case .isName:
            LogoPrimitiveMeta(
                name: "NAME?",
                description: "Tests whether variable name exists in environment.",
                localizedDescriptionKey: "logo.doc.isname",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "varname", required: true)],
                examples: [LogoPrimitiveExample(input: "NAME? \"count")]
            )

        case .count:
            LogoPrimitiveMeta(
                name: "COUNT",
                description: "Returns item count of list, array, or character count of word.",
                localizedDescriptionKey: "logo.doc.count",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "data", required: true)],
                examples: [LogoPrimitiveExample(input: "COUNT [1 2 3 4]", output: "4")]
            )

        case .ascii:
            LogoPrimitiveMeta(
                name: "ASCII",
                description: "Returns integer Unicode code point of character.",
                localizedDescriptionKey: "logo.doc.ascii",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "char", required: true)],
                examples: [LogoPrimitiveExample(input: "ASCII \"A", output: "65")]
            )

        case .char:
            LogoPrimitiveMeta(
                name: "CHAR",
                description: "Returns character string corresponding to integer Unicode code point.",
                localizedDescriptionKey: "logo.doc.char",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "codepoint", required: true)],
                examples: [LogoPrimitiveExample(input: "CHAR 65", output: "A")]
            )

        case .member:
            LogoPrimitiveMeta(
                name: "MEMBER",
                description: "Returns sublist or subword starting from first occurrence of item.",
                localizedDescriptionKey: "logo.doc.member",
                source: .ucbLogo,
                parameters: [
                    LogoPrimitiveParameter(name: "item", required: true),
                    LogoPrimitiveParameter(name: "data", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "MEMBER 3 [1 2 3 4 5]", output: "[3 4 5]")]
            )

        case .uppercase:
            LogoPrimitiveMeta(
                name: "UPPERCASE",
                description: "Converts word to uppercase characters.",
                localizedDescriptionKey: "logo.doc.uppercase",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "word", required: true)],
                examples: [LogoPrimitiveExample(input: "UPPERCASE \"hello", output: "HELLO")]
            )

        case .lowercase:
            LogoPrimitiveMeta(
                name: "LOWERCASE",
                description: "Converts word to lowercase characters.",
                localizedDescriptionKey: "logo.doc.lowercase",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "word", required: true)],
                examples: [LogoPrimitiveExample(input: "LOWERCASE \"HELLO", output: "hello")]
            )

        case .standout:
            LogoPrimitiveMeta(
                name: "STANDOUT",
                description: "Wraps text with ANSI reverse standout escape codes.",
                localizedDescriptionKey: "logo.doc.standout",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "text", required: true)],
                examples: [LogoPrimitiveExample(input: "STANDOUT \"Alert")]
            )

        case .translit:
            LogoPrimitiveMeta(
                name: "TRANSLIT",
                description: "Applies ICU transliteration transform to string.",
                localizedDescriptionKey: "logo.doc.translit",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "transform", required: true),
                    LogoPrimitiveParameter(name: "string", required: true)
                ],
                examples: [LogoPrimitiveExample(input: "TRANSLIT \"Traditional-Simplified \"繁體", output: "繁体")]
            )

        case .transformToHans:
            LogoPrimitiveMeta(
                name: "TOHANS",
                description: "Converts Traditional Chinese text to Simplified Chinese.",
                localizedDescriptionKey: "logo.doc.tohans",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "TOHANS \"繁體中文", output: "繁体中文")]
            )

        case .transformToHant:
            LogoPrimitiveMeta(
                name: "TOHANT",
                description: "Converts Simplified Chinese text to Traditional Chinese.",
                localizedDescriptionKey: "logo.doc.tohant",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "TOHANT \"简体中文", output: "簡體中文")]
            )

        case .transformToLatin:
            LogoPrimitiveMeta(
                name: "TOLATIN",
                description: "Transliterates text to Latin romanized script.",
                localizedDescriptionKey: "logo.doc.tolatin",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "TOLATIN \"中文", output: "zhōng wén")]
            )

        case .transformToHiragana:
            LogoPrimitiveMeta(
                name: "TOHIRAGANA",
                description: "Converts any text to Hiragana.",
                localizedDescriptionKey: "logo.doc.tohiragana",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "TOHIRAGANA \"カタカナ", output: "かたかな")]
            )

        case .transformToKatakana:
            LogoPrimitiveMeta(
                name: "TOKATAKANA",
                description: "Converts any text to Katakana.",
                localizedDescriptionKey: "logo.doc.tokatakana",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "TOKATAKANA \"ひらがな", output: "ヒラガナ")]
            )

        case .transformToRomaji:
            LogoPrimitiveMeta(
                name: "TOROMAJI",
                description: "Transliterates Japanese Kana to Romaji.",
                localizedDescriptionKey: "logo.doc.toromaji",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "TOROMAJI \"とうきょう", output: "tōkyō")]
            )

        case .spacingCJK:
            LogoPrimitiveMeta(
                name: "SPACING.CJK",
                description: "Formats typography spacing between CJK and Western alphanumeric characters.",
                localizedDescriptionKey: "logo.doc.spacingcjk",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "SPACING.CJK \"使用Zago編輯器\"", output: "使用 Zago 編輯器")]
            )

        case .charCount:
            LogoPrimitiveMeta(
                name: "CHARCOUNT",
                description: "Counts total Unicode grapheme clusters in string.",
                localizedDescriptionKey: "logo.doc.countchars",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "CHARCOUNT \"Hello 世界", output: "8")]
            )

        case .charCountCJK:
            LogoPrimitiveMeta(
                name: "CHARCOUNT.CJK",
                description: "Counts CJK ideograph characters in string.",
                localizedDescriptionKey: "logo.doc.countcjk",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "CHARCOUNT.CJK \"Hello 世界", output: "2")]
            )

        case .charCountWords:
            LogoPrimitiveMeta(
                name: "CHARCOUNT.WORDS",
                description: "Counts words in natural language string.",
                localizedDescriptionKey: "logo.doc.countwords",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "CHARCOUNT.WORDS \"Quick brown fox", output: "3")]
            )

        case .charCountEmoji:
            LogoPrimitiveMeta(
                name: "CHARCOUNT.EMOJI",
                description: "Counts emoji glyphs in string.",
                localizedDescriptionKey: "logo.doc.countemoji",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "CHARCOUNT.EMOJI \"🚀✨🎉", output: "3")]
            )

        case .charCountLines:
            LogoPrimitiveMeta(
                name: "CHARCOUNT.LINES",
                description: "Counts lines in multiline string.",
                localizedDescriptionKey: "logo.doc.countlines",
                source: .zago,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "CHARCOUNT.LINES :multilineStr")]
            )

        case .parse:
            LogoPrimitiveMeta(
                name: "PARSE",
                description: "Parses string into a LOGO token list.",
                localizedDescriptionKey: "logo.doc.parse",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "string", required: true)],
                examples: [LogoPrimitiveExample(input: "PARSE \"[FD 10 RT]", output: "[FD 10 RT]")]
            )

        case .runparse:
            LogoPrimitiveMeta(
                name: "RUNPARSE",
                description: "Parses word string into tokenized list.",
                localizedDescriptionKey: "logo.doc.runparse",
                source: .ucbLogo,
                parameters: [LogoPrimitiveParameter(name: "word", required: true)],
                examples: [LogoPrimitiveExample(input: "RUNPARSE \"FD 10", output: "[FD 10]")]
            )

        default: nil
    }
}
}
