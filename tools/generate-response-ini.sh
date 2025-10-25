#!/usr/bin/env bash
#
# Generate response.ini files for OpenEdge container builds from license addendum file
# Native Linux/macOS implementation (no PowerShell required)
#
# This script parses a Progress Software License Addendum file and generates tailored
# response.ini files for each required container build (compiler, db_adv, pas_dev, pas_base).
# It extracts company name, serial numbers, and control codes for each product.
# For versions 12.2.17-12.2.18 and 12.8.4-12.8.8, it also generates response_update.ini files.
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Global variables
LICENSE_FILE=""
VERSION=""
DEVCONTAINER=false
FORCE=false
VERBOSE=false

# Container build configurations
get_build_config() {
    local build_name="$1"
    case "$build_name" in
        "compiler")
            echo "4GL Development System|Client Networking|Progress Dev AppServer for OE"
            ;;
        "db_adv")
            echo "OE RDBMS Adv Enterprise"
            ;;
        "pas_dev")
            echo "Progress Dev AS for OE|Progress Dev AppServer for OE"
            ;;
        "pas_base")
            echo "Progress App Server for OE|Progress Prod AppServer for OE"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Get list of all build configurations
get_build_names() {
    echo "compiler db_adv pas_dev pas_base"
}

# Usage function
show_usage() {
    echo "Generate response.ini files for OpenEdge container builds"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -l, --license FILE      Path to license addendum file"
    echo "  -v, --version VERSION   OpenEdge version (e.g., 12.8.9)"
    echo "  -d, --devcontainer      Generate for all devcontainer images"
    echo "  -f, --force            Overwrite existing files without prompting"
    echo "  --verbose              Enable verbose output"
    echo "  -h, --help             Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Interactive mode"
    echo "  $0 -l /path/to/license.txt           # Use specific license file"
    echo "  $0 -d -v 12.8.9                     # Generate for devcontainer"
}

# Verbose logging function
log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${GRAY}[VERBOSE] $1${NC}" >&2
    fi
}

# Check if version requires response_update.ini
requires_update_ini() {
    local version="$1"
    
    if [[ -z "$version" ]]; then
        return 1
    fi
    
    # Parse version
    if [[ "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
        local major="${BASH_REMATCH[1]}"
        local minor="${BASH_REMATCH[2]}"
        local patch="${BASH_REMATCH[3]}"
        
        # Check if version requires response_update.ini
        # 12.2.17-12.2.18 or 12.8.4-12.8.8
        if [[ "$major" -eq 12 && "$minor" -eq 2 && "$patch" -ge 17 && "$patch" -le 18 ]]; then
            return 0
        fi
        if [[ "$major" -eq 12 && "$minor" -eq 8 && "$patch" -ge 4 && "$patch" -le 8 ]]; then
            return 0
        fi
    fi
    
    return 1
}

# Validate license file format
validate_license_file() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        echo -e "${RED}Error: License file not found: $file_path${NC}" >&2
        return 1
    fi
    
    local content
    content=$(cat "$file_path")
    
    # Check for required format markers
    if ! echo "$content" | grep -q "Progress Software Corporation.*License Addendum"; then
        echo -e "${RED}Error: Invalid license file format: Missing Progress Software Corporation License Addendum header${NC}" >&2
        return 1
    fi
    
    if ! echo "$content" | grep -q "Product.*Ship.*Units.*Release"; then
        echo -e "${RED}Error: Invalid license file format: Missing product listing section${NC}" >&2
        return 1
    fi
    
    if ! echo "$content" | grep -q "Serial #:.*[0-9].*Rel:.*[0-9].*Control#:"; then
        echo -e "${RED}Error: Invalid license file format: Missing serial number and control code information${NC}" >&2
        return 1
    fi
    
    echo -e "${GREEN}License file format validated${NC}"
    return 0
}

# Extract company name from license file
get_company_name() {
    local content="$1"
    
    # Extract company name from "Registered To" section
    # Format: "Registered To:   12345  Full Company Name (ABBREV)"
    # Or:     "Registered To:   12345  Company Name                         Extended Name"
    local full_name
    full_name=$(echo "$content" | sed -n 's/^Registered To:[[:space:]]*[0-9][0-9]*[[:space:]]*\(.*\)$/\1/p' | head -1)
    if [[ -n "$full_name" ]]; then
        # If there are 5+ consecutive spaces, take only the part before them
        if echo "$full_name" | grep -q '     '; then
            company_name=$(echo "$full_name" | sed 's/     .*//' | xargs)
            log_verbose "Found company name (before whitespace): $company_name (from: $full_name)"
            echo "$company_name"
            return 0
        fi
        
        # Try to extract abbreviated name in parentheses
        local abbrev
        abbrev=$(echo "$full_name" | sed -n 's/.*(\([^)]*\))[[:space:]]*$/\1/p')
        if [[ -n "$abbrev" ]]; then
            company_name=$(echo "$abbrev" | xargs)
            log_verbose "Found abbreviated company name: $company_name (from: $full_name)"
            echo "$company_name"
            return 0
        fi
        
        # If no special formatting, use full name
        company_name=$(echo "$full_name" | xargs)
        log_verbose "Found company name: $company_name"
        echo "$company_name"
        return 0
    fi
    
    # Fallback: try Customer/Partner section
    full_name=$(echo "$content" | sed -n 's/^Customer\/Partner:[[:space:]]*[0-9][0-9]*[[:space:]]*\(.*\)$/\1/p' | head -1)
    if [[ -n "$full_name" ]]; then
        # Similar processing as above
        if echo "$full_name" | grep -q '     '; then
            company_name=$(echo "$full_name" | sed 's/     .*//' | xargs)
            log_verbose "Found company name (fallback, before whitespace): $company_name (from: $full_name)"
            echo "$company_name"
            return 0
        fi
        
        abbrev=$(echo "$full_name" | sed -n 's/.*(\([^)]*\))[[:space:]]*$/\1/p')
        if [[ -n "$abbrev" ]]; then
            company_name=$(echo "$abbrev" | xargs)
            log_verbose "Found abbreviated company name (fallback): $company_name (from: $full_name)"
            echo "$company_name"
            return 0
        fi
        
        company_name=$(echo "$full_name" | xargs)
        log_verbose "Found company name (fallback): $company_name"
        echo "$company_name"
        return 0
    fi
    
    echo -e "${RED}Error: Could not extract company name from license file${NC}" >&2
    return 1
}

# Parse license products from file
parse_license_products() {
    local content="$1"
    local temp_file
    temp_file=$(mktemp)
    
    # Known product patterns (order matters - more specific first)
    local known_products=(
        "4GL Development System"
        "Client Networking"
        "Progress Dev AS for OE"
        "Progress Dev AppServer for OE"
        "Progress Prod AppServer for OE"
        "OE RDBMS Adv Enterprise"
        "OE RDBMS Enterprise"
        "OE WorkGroup RDBMS"
        "OE RDBMS Workgroup"
        "OE RDBMS Personal"
        "OE RDBMS"
        "OpenEdge Transparent Dat"
        "OE AuthenticationGateway"
        "Progress App Server for OE"
        "Progress AppServer for OE"
    )
    
    # Convert content to array of lines
    local lines=()
    while IFS= read -r line; do
        lines+=("$line")
    done <<< "$content"
    
    # Process each line looking for serial/control patterns
    for ((i=0; i<${#lines[@]}; i++)); do
        local line="${lines[i]}"
        
        # Match product lines with serial and control codes
        # Format: "Linux 64bit        Serial #:    006275022  Rel: 12.8    Control#:YZFRS XQP2M NMG?R"
        if [[ "$line" =~ Serial\ \#:[[:space:]]+([0-9]+)[[:space:]]+Rel:[[:space:]]+([0-9.]+)[[:space:]]+Control\#:(.+)$ ]]; then
            local serial="${BASH_REMATCH[1]}"
            local release="${BASH_REMATCH[2]}"
            local control="${BASH_REMATCH[3]}"
            
            # Look backwards for product name (skip empty lines and platform lines)
            for ((j=i-1; j>=0 && j>=(i-5); j--)); do
                local prev_line="${lines[j]}"
                
                # Skip empty lines
                if [[ -z "${prev_line// }" ]]; then
                    continue
                fi
                
                # Skip platform/architecture lines
                if [[ "$prev_line" =~ ^[[:space:]]*(Linux|Windows|Solaris|AIX|HP-UX|Mac)[[:space:]]+(32bit|64bit) ]]; then
                    continue
                fi
                
                # Check against known products
                for product in "${known_products[@]}"; do
                    if [[ "$prev_line" =~ ^[[:space:]]*${product} ]]; then
                        local product_key="${product}|${serial}"
                        
                        # Check if already found (avoid duplicates)
                        if ! grep -q "^${product_key}|" "$temp_file" 2>/dev/null; then
                            echo "${product_key}|${release}|${control}" >> "$temp_file"
                            log_verbose "Found product (backward search): $product (Serial: $serial, Control: $control, Line: $i, matched from line: $j)"
                        else
                            log_verbose "Duplicate product key found (backward search): $product_key (skipping, Line: $i)"
                        fi
                        break 2  # Break both loops
                    fi
                done
            done
        fi
        
        # Also check for bundle products with separate control codes
        # Format: "      Progress Dev AppServer for OE          Units: 1"
        if [[ "$line" =~ ^[[:space:]]+(.+)[[:space:]]{2,}Units:[[:space:]]+[0-9]+ ]]; then
            local potential_product="${BASH_REMATCH[1]// /}"
            potential_product="${potential_product// /}"
            
            # Check if this matches known products
            for product in "${known_products[@]}"; do
                if [[ "$potential_product" == "$product" ]]; then
                    # Look ahead for serial and control
                    for ((j=i+1; j<${#lines[@]} && j<=(i+3); j++)); do
                        local next_line="${lines[j]}"
                        if [[ "$next_line" =~ Serial\ \#:[[:space:]]+([0-9]+)[[:space:]]+Rel:[[:space:]]+([0-9.]+)[[:space:]]+Control\#:(.+)$ ]]; then
                            local serial="${BASH_REMATCH[1]}"
                            local release="${BASH_REMATCH[2]}"
                            local control="${BASH_REMATCH[3]}"
                            local product_key="${product}|${serial}"
                            
                            if ! grep -q "^${product_key}|" "$temp_file" 2>/dev/null; then
                                echo "${product_key}|${release}|${control}" >> "$temp_file"
                                log_verbose "Found bundle product (Units search): $product (Serial: $serial, Control: $control, Line: $i)"
                            else
                                log_verbose "Duplicate bundle product key found (Units search): $product_key (skipping, Line: $i)"
                            fi
                            break 2
                        fi
                    done
                    break
                fi
            done
        fi
    done
    
    # Output the results
    if [[ -f "$temp_file" ]]; then
        cat "$temp_file"
        rm -f "$temp_file"
    fi
}

# Generate response.ini file
generate_response_ini() {
    local target_path="$1"
    local company_name="$2"
    local products_data="$3"
    local template_file="$4"
    
    local output_file="$target_path/response.ini"
    
    # Check if file exists
    if [[ -f "$output_file" && "$FORCE" != "true" ]]; then
        echo -n "File $output_file already exists. Overwrite? (y/N): "
        read -r response
        if [[ "$response" != "y" && "$response" != "Y" ]]; then
            echo -e "${YELLOW}Skipping $output_file${NC}"
            return 0
        fi
    fi
    
    # Check template file
    if [[ ! -f "$template_file" ]]; then
        echo -e "${RED}Error: Template file not found: $template_file${NC}" >&2
        return 1
    fi
    
    local content
    content=$(cat "$template_file")
    
    # Parse Product Configuration sections from template
    local config_num=1
    while [[ "$content" =~ \[Product\ Configuration\ ${config_num}\][^\[]*prodname=([^\r\n]+) ]]; do
        local template_prod_name="${BASH_REMATCH[1]// /}"
        
        # Normalize template name for comparison
        local normalized_template_name
        normalized_template_name=$(echo "$template_prod_name" | sed 's/AppServer/AS/g; s/App Server/AS/g; s/ProdAS/AS/g; s/Prod AS/AS/g; s/Prod //g; s/Production //g')
        
        # Find matching product from license data
        local matching_product=""
        local best_match=""
        
        while IFS='|' read -r product_key release control; do
            if [[ -z "$product_key" ]]; then continue; fi
            
            local product_name="${product_key%|*}"
            local serial="${product_key#*|}"
            
            # Normalize product name
            local normalized_product_name
            normalized_product_name=$(echo "$product_name" | sed 's/AppServer/AS/g; s/App Server/AS/g; s/ProdAS/AS/g; s/Prod AS/AS/g; s/Prod //g; s/Production //g')
            
            # Check for matches (exact, contains, etc.)
            if [[ "$normalized_product_name" == "$normalized_template_name" ]] || \
               [[ "$normalized_template_name" == *"$normalized_product_name"* ]] || \
               [[ "$normalized_product_name" == *"$normalized_template_name"* ]] || \
               [[ "$product_name" == "$template_prod_name" ]]; then
                
                # Prefer products with control codes
                if [[ -n "$control" && -z "$best_match" ]] || [[ -n "$control" && -z "${best_match##*|*|}" ]]; then
                    best_match="$product_name|$serial|$release|$control"
                    log_verbose "Matched template product '$template_prod_name' to license product '$product_name' (Serial: $serial, Control: $control)"
                fi
            fi
        done <<< "$products_data"
        
        if [[ -n "$best_match" ]]; then
            IFS='|' read -r match_name match_serial match_release match_control <<< "$best_match"
            
            # Find and update the section
            local section_pattern="\[Product Configuration ${config_num}\][^\[]*"
            if [[ "$content" =~ $section_pattern ]]; then
                local section="${BASH_REMATCH[0]}"
                local updated_section="$section"
                
                # Update fields using sed-like replacements
                updated_section=$(echo "$updated_section" | sed "s/^name=.*/name=$company_name/m")
                updated_section=$(echo "$updated_section" | sed "s/^serial=.*/serial=$match_serial/m")
                updated_section=$(echo "$updated_section" | sed "s/^control=.*/control=$match_control/m")
                
                log_verbose "Updated section for Product Configuration $config_num"
                
                # Replace section in content
                content="${content/$section/$updated_section}"
            else
                log_verbose "Warning: Could not find section pattern for Product Configuration $config_num"
            fi
        else
            log_verbose "Warning: No license data found for template product: $template_prod_name"
        fi
        
        ((config_num++))
    done
    
    # Write output
    echo "$content" > "$output_file"
    echo -e "${GREEN}Generated: $output_file${NC}"
}

# Generate response_update.ini file
generate_response_update_ini() {
    local target_path="$1"
    local company_name="$2"
    local version="$3"
    local template_file="$4"
    
    local output_file="$target_path/response_update.ini"
    
    # Check if file exists
    if [[ -f "$output_file" && "$FORCE" != "true" ]]; then
        echo -n "File $output_file already exists. Overwrite? (y/N): "
        read -r response
        if [[ "$response" != "y" && "$response" != "Y" ]]; then
            echo -e "${YELLOW}Skipping $output_file${NC}"
            return 0
        fi
    fi
    
    # Check template file
    if [[ ! -f "$template_file" ]]; then
        echo -e "${RED}Error: Template file not found: $template_file${NC}" >&2
        return 1
    fi
    
    local template
    template=$(cat "$template_file")
    
    # Update company name in [Application] section
    template=$(echo "$template" | sed "s/Company=.*/Company=$company_name/")
    
    # Update version if provided
    if [[ "$version" =~ ^([0-9]+)\.([0-9]+) ]]; then
        local major_minor="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
        template=$(echo "$template" | sed "s/Version=[0-9.]*/Version=$major_minor/")
        
        # Update backup directory path with version
        if [[ "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
            local full_version="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
            template=$(echo "$template" | sed "s|_sSPBackupDir=/usr/dlc/Backup[0-9.]*|_sSPBackupDir=/usr/dlc/Backup$full_version|")
        fi
    fi
    
    # Write output
    echo "$template" > "$output_file"
    echo -e "${GREEN}Generated: $output_file${NC}"
}

# Find license file automatically
find_license_file() {
    local addendum_dir="$ROOT_DIR/addendum"
    
    if [[ ! -d "$addendum_dir" ]]; then
        echo -e "${RED}Error: Addendum directory not found: $addendum_dir${NC}" >&2
        return 1
    fi
    
    # Look for license files
    local license_files=()
    while IFS= read -r -d '' file; do
        license_files+=("$file")
    done < <(find "$addendum_dir" -name "*.txt" \( -name "US*" -o -name "*License*Addendum*" \) -print0 2>/dev/null)
    
    if [[ ${#license_files[@]} -eq 0 ]]; then
        echo -e "${RED}Error: No license addendum file found in $addendum_dir${NC}" >&2
        echo "Please specify -l/--license parameter." >&2
        return 1
    fi
    
    if [[ ${#license_files[@]} -gt 1 ]]; then
        echo -e "${YELLOW}Multiple license files found:${NC}"
        for i in "${!license_files[@]}"; do
            echo "  [$i] $(basename "${license_files[i]}")"
        done
        echo -n "Select file number: "
        read -r selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -lt ${#license_files[@]} ]]; then
            echo "${license_files[selection]}"
        else
            echo -e "${RED}Error: Invalid selection${NC}" >&2
            return 1
        fi
    else
        echo "${license_files[0]}"
    fi
}

# Main execution function
main() {
    echo -e "\n${CYAN}=== OpenEdge Response.ini Generator (Linux) ===${NC}"
    echo ""
    
    # Find license file if not provided
    if [[ -z "$LICENSE_FILE" ]]; then
        LICENSE_FILE=$(find_license_file)
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi
    
    echo -e "${CYAN}Using license file: $LICENSE_FILE${NC}"
    echo ""
    
    # Validate license file format
    if ! validate_license_file "$LICENSE_FILE"; then
        return 1
    fi
    
    # Read license file
    local license_content
    license_content=$(cat "$LICENSE_FILE")
    
    # Extract company name
    local company_name
    company_name=$(get_company_name "$license_content")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    echo -e "${CYAN}Company Name: $company_name${NC}"
    echo ""
    
    # Extract products
    local all_products
    all_products=$(parse_license_products "$license_content")
    local product_count
    product_count=$(echo "$all_products" | wc -l)
    echo -e "${CYAN}Found $product_count licensed products${NC}"
    
    # Debug: Show all parsed products if verbose
    if [[ "$VERBOSE" == "true" ]]; then
        log_verbose "=== All Parsed Products ==="
        while IFS='|' read -r product_key release control; do
            if [[ -n "$product_key" ]]; then
                local product_name="${product_key%|*}"
                local serial="${product_key#*|}"
                log_verbose "  $product_name | Serial: $serial | Control: $control"
            fi
        done <<< "$all_products"
        log_verbose "==========================="
    fi
    
    # Detect version from license file if not provided
    local detected_version="$VERSION"
    if [[ -z "$detected_version" ]]; then
        # Try to extract version from first product
        detected_version=$(echo "$all_products" | head -1 | cut -d'|' -f3)
    fi
    
    # Check if response_update.ini is needed
    local requires_update=false
    if requires_update_ini "$detected_version"; then
        requires_update=true
        echo -e "${CYAN}Version $detected_version requires response_update.ini files${NC}"
    fi
    echo ""
    
    # Generate response.ini for each build configuration
    for build_name in $(get_build_names); do
        local build_path="$ROOT_DIR/$build_name"
        local required_products
        required_products=$(get_build_config "$build_name")
        
        echo -e "${YELLOW}Processing: $build_name${NC}"
        
        # Find matching products
        local matched_products=""
        IFS='|' read -ra required_array <<< "$required_products"
        
        while IFS='|' read -r product_key release control; do
            if [[ -z "$product_key" ]]; then continue; fi
            
            local product_name="${product_key%|*}"
            local serial="${product_key#*|}"
            
            # Check if this product matches any required product
            for required in "${required_array[@]}"; do
                if [[ "$product_name" == "$required" ]] || [[ "$product_name" == *"$required"* ]]; then
                    matched_products+="$product_key|$release|$control"$'\n'
                    echo -e "  ${GRAY}- Found: $product_name (Serial: $serial, Control: $control)${NC}"
                    break
                fi
            done
        done <<< "$all_products"
        
        if [[ -z "$matched_products" ]]; then
            echo -e "  ${YELLOW}No matching products found for $build_name${NC}"
            continue
        fi
        
        # Generate response.ini
        local template_file="$build_path/response_ini_example.txt"
        if [[ -f "$template_file" ]]; then
            generate_response_ini "$build_path" "$company_name" "$matched_products" "$template_file"
        else
            echo -e "  ${YELLOW}Warning: Template file not found: $template_file${NC}"
        fi
        
        # Generate response_update.ini if needed
        if [[ "$requires_update" == "true" ]]; then
            local update_template_file="$build_path/response_update_ini_example.txt"
            if [[ -f "$update_template_file" ]]; then
                generate_response_update_ini "$build_path" "$company_name" "$detected_version" "$update_template_file"
            else
                echo -e "  ${YELLOW}Warning: response_update_ini_example.txt not found in $build_path${NC}"
            fi
        fi
        
        echo ""
    done
    
    echo -e "${GREEN}=== Generation Complete ===${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "1. Review the generated response.ini files in each component directory"
    echo "2. Verify the license information is correct"
    echo "3. Build your Docker containers"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--license)
            LICENSE_FILE="$2"
            shift 2
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -d|--devcontainer)
            DEVCONTAINER=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Run main function
if ! main; then
    echo -e "\n${RED}Error: Response.ini generation failed!${NC}" >&2
    exit 1
fi
