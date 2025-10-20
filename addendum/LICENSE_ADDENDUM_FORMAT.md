# License Addendum File Format

This document describes the expected format for Progress Software License Addendum files used by the `Generate-ResponseIni.ps1` script.

## File Location

Place your license addendum file in the `addendum/` directory with a `.txt` extension. The script will auto-detect files matching:
- `US*.txt` (e.g., `US263472 License Addendum.txt`)
- `*License*Addendum*.txt`

## Required Format

Your license addendum file must contain the following sections:

### 1. Header Section

```
Progress Software Corporation ('PSC') License Addendum
```

This header identifies the document as a valid Progress license addendum.

### 2. Company Information

```
Customer/Partner:10011021                 Registered To:10157947
    Progress Software                         Progress Software ESD
    15 Wayside Rd Ste 400                     Internal Use
    BURLINGTON, MA 01803                      15 Wayside Rd Ste 400
    United States                             BURLINGTON, MA 01803
                                              US
    Phone #781-275-4000                       Phone #
      Fax #                                     Fax #
```

The script extracts the company name from the "Registered To" section (e.g., "Progress Software ESD").

### 3. Product Listing Header

```
Product                   Ship      Units  Release  MediaID Title
PSC Order #               Ord. Date
------------------------- --------- ------ -------- ------- --------------
```

This table header precedes the product listings.

### 4. Product Entries

Each product entry follows this format:

```
 4GL Development System             1      12.8     1000128 OE 12.8 FF
    US263472              01/11/24 PO: 12.8 Linux 64b DryRun
    Linux 64bit        Serial #:    006275022  Rel: 12.8    Control#:YZFRS XQP2M NMG?R
    Unit Type: Named User                                      LicenseID: None
```

**Key elements:**
- **Product name** (first line): e.g., "4GL Development System"
- **Serial number**: e.g., "006275022"
- **Release version**: e.g., "12.8"
- **Control code**: e.g., "YZFRS XQP2M NMG?R"

### 5. Bundle Products (Optional)

Some products are part of bundles and have a special format:

```
 PAS for OE DEV Bundle              1      12.8     1000128 OE 12.8 FF
    US263472              01/11/24 PO: 12.8 Linux 64b DryRun
    Linux 64bit        Serial #:    006275040  Rel: 12.8    Control#:
    Unit Type: Named User                                      LicenseID: None
 ** USE THE SERIAL NUMBER AND CONTROL CODES BELOW TO INSTALL YOUR PRODUCTS.

 Linux 64bit
    OE AuthenticationGateway               Units: 1
    Serial #:    006275040   Rel: 12.8     Control#:X?HSS XPP6D NMC?4
    Progress Dev AppServer for OE          Units: 1
    Serial #:    006275040   Rel: 12.8     Control#:Z8DRS 2PP2N N4C?4
```

Bundle products have:
- A parent product entry (may have empty control code)
- A "USE THE SERIAL NUMBER AND CONTROL CODES BELOW" notice
- Individual component products with their own control codes

## Recognized Products

The script recognizes and processes these products:

| Product Name | Used In Container |
|--------------|-------------------|
| 4GL Development System | compiler |
| Client Networking | compiler |
| Progress Dev AS for OE | compiler, pas_dev |
| Progress Prod AppServer for OE | pas_base |
| Progress App Server for OE | pas_base |
| OE RDBMS Adv Enterprise | db_adv |
| OE AuthenticationGateway | (optional) |

## Example Complete Entry

```
Progress Software Corporation ('PSC') License Addendum

License Notice:
    [License agreement text...]

Progress    Licensed Products as of January 12, 2024 for Linux 64bit

    Customer/Partner:10011021                 Registered To:10157947
        Progress Software                         Progress Software ESD
        15 Wayside Rd Ste 400                     Internal Use
        BURLINGTON, MA 01803                      15 Wayside Rd Ste 400
        United States                             BURLINGTON, MA 01803
                                                  US
        Phone #781-275-4000                       Phone #
          Fax #                                     Fax #

Product                   Ship      Units  Release  MediaID Title
PSC Order #               Ord. Date
------------------------- --------- ------ -------- ------- --------------
 4GL Development System             1      12.8     1000128 OE 12.8 FF
    US263472              01/11/24 PO: 12.8 Linux 64b DryRun
    Linux 64bit        Serial #:    006275022  Rel: 12.8    Control#:YZFRS XQP2M NMG?R
    Unit Type: Named User                                      LicenseID: None

 Client Networking                  25     12.8     1000128 OE 12.8 FF
    US263472              01/11/24 PO: 12.8 Linux 64b DryRun
    Linux 64bit        Serial #:    006275023  Rel: 12.8    Control#:Z8DSS XPPEN NMRYR
    Unit Type: Named User                                      LicenseID: None

 OE RDBMS Adv Enterprise            75     12.8     1000128 OE 12.8 FF
    US263472              01/11/24 PO: 12.8 Linux 64b DryRun
    Linux 64bit        Serial #:    006275036  Rel: 12.8    Control#:YYB9S TQPAM MMC?8
    Unit Type: Named User                                      LicenseID: None
```

## Validation

The script performs these validations:

1. ✅ **Header check**: Verifies "Progress Software Corporation" and "License Addendum" are present
2. ✅ **Product listing**: Confirms the product table header exists
3. ✅ **Serial/Control format**: Ensures at least one product has serial number and control code

## Troubleshooting

### "Invalid license file format: Missing header"

Your file doesn't contain the required "Progress Software Corporation ('PSC') License Addendum" header.

**Solution**: Ensure you're using an official Progress license addendum file.

### "Invalid license file format: Missing product listing section"

The product table header is missing or malformed.

**Solution**: Check that your file contains the "Product ... Ship ... Units ... Release" table header.

### "Invalid license file format: Missing serial number and control code information"

No valid product entries with serial numbers and control codes were found.

**Solution**: Verify your license file contains complete product entries with:
- Serial #: [number]
- Rel: [version]
- Control#: [code]

### "Could not extract company name"

The script couldn't find the company name in the expected locations.

**Solution**: Check that your file has either:
- "Registered To:" section with company name
- "Customer/Partner:" section with company name

## Security Notes

⚠️ **Important Security Reminders:**

1. **Never commit license files to version control** - They contain sensitive information
2. **Keep license files secure** - Store them in a secure location
3. **Use .gitignore** - The `addendum/` directory should be in `.gitignore` (except for placeholder files)
4. **Different licenses for different environments** - Use separate licenses for dev/test/prod

## Related Documentation

- [Generate-ResponseIni.ps1 README](../tools/README_Generate-ResponseIni.md) - Script usage guide
- [RESPONSE_INI_GUIDE.md](../RESPONSE_INI_GUIDE.md) - Response.ini file format guide
- [Progress License Documentation](https://docs.progress.com/) - Official Progress documentation
