# How Long

Small cli app to calculate how much time I've worked.

## Example

```bash
$ hl 920 1237 1345
warning: Missing last entry. Ignoring value 13:45.
2025-08-07 03:17 | 09:20 12:37 13:45
$ hl 820 1237 1345 1734
2025-08-07 08:06 | 08:20 12:37 13:45 17:34
# When I'm happy with the result, I simply append to a text file.
$ hl 820 1237 1345 1734 >> fichajes.txt
```
