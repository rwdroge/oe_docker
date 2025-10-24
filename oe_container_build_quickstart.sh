#!/usr/bin/env bash
#
# OpenEdge Container Build Quickstart
# Interactive tool for building OpenEdge Docker containers on Linux/macOS
#
# This script provides an interactive menu to:
# 1. Generate response.ini files from license addendum
# 2. Create all images for DevContainer configuration
# 3. Create specific container images with dependency validation
#
# Focused on devcontainer workflows with simplified interface.
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

# Get script directory (now in root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$SCRIPT_DIR/tools"

# Global variables
DOCKER_USERNAME=""
VERSION=""
ACTION=""
COMPONENT=""
LICENSE_FILE=""
FORCE=false
BATCH=false

# Helper function to show menu
show_menu() {
    local docker_username="$1"
    
    clear
    echo -e "${CYAN}============================================================${NC}"
    echo -e "${CYAN}      OpenEdge Container Build Quickstart                  ${NC}"
    echo -e "${CYAN}============================================================${NC}"
    echo ""
    echo -e "  ${GREEN}Docker Username: $docker_username${NC}"
    echo ""
    echo -e "  ${YELLOW}1. Generate response.ini files from license addendum${NC}"
    echo -e "  ${YELLOW}2. Create all images for DevContainer configuration${NC}"
    echo -e "  ${YELLOW}3. Create specific container images${NC}"
    echo -e "  ${YELLOW}4. Exit${NC}"
    echo ""
}

# Helper function to get user choice
get_user_choice() {
    local prompt="$1"
    shift
    local valid_choices=("$@")
    local choice
    
    while true; do
        read -p "$prompt" choice
        for valid in "${valid_choices[@]}"; do
            if [[ "$choice" == "$valid" ]]; then
                echo "$choice"
                return
            fi
        done
        echo -e "${RED}Invalid choice. Please try again.${NC}"
    done
}

# Helper function to run Generate-ResponseIni.ps1
invoke_generate_response_ini() {
    local version="$1"
    local license_file="$2"
    local force="$3"
    local devcontainer="$4"
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Generating response.ini files...${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Check if pwsh is available
    if ! command -v pwsh &> /dev/null; then
        echo -e "${RED}Error: PowerShell Core (pwsh) is not installed.${NC}"
        echo ""
        echo "Please install PowerShell Core:"
        echo "  Ubuntu/Debian: sudo apt-get install -y powershell"
        echo "  macOS: brew install --cask powershell"
        echo "  Other: https://github.com/PowerShell/PowerShell#get-powershell"
        return 1
    fi
    
    local generate_script="$TOOLS_DIR/Generate-ResponseIni.ps1"
    local pwsh_args=()
    
    if [[ -n "$version" ]]; then
        pwsh_args+=("-Version" "$version")
    fi
    if [[ -n "$license_file" ]]; then
        pwsh_args+=("-LicenseFile" "$license_file")
    fi
    if [[ "$force" == "true" ]]; then
        pwsh_args+=("-Force")
    fi
    if [[ "$devcontainer" == "true" ]]; then
        pwsh_args+=("-Devcontainer")
    fi
    
    if pwsh "$generate_script" "${pwsh_args[@]}"; then
        echo ""
        echo -e "${GREEN} Response.ini generation completed!${NC}"
        return 0
    else
        echo ""
        echo -e "${RED} Response.ini generation failed!${NC}"
        return 1
    fi
}

# Helper function to run build scripts
invoke_build_images() {
    local component="$1"
    local version="$2"
    local docker_username="$3"
    local devcontainer_only="$4"
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Building Docker images...${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Check if component contains comma-separated list
    if [[ "$component" == *","* ]]; then
        # Build multiple components
        local build_script="$TOOLS_DIR/build-image.sh"
        IFS=',' read -ra components <<< "$component"
        
        for comp in "${components[@]}"; do
            comp=$(echo "$comp" | xargs) # trim whitespace
            
            # Validate component
            if [[ ! "$comp" =~ ^(compiler|db_adv|pas_dev|devcontainer|sports2020-db)$ ]]; then
                echo -e "${RED}Invalid component: $comp${NC}"
                echo -e "${YELLOW}Valid components: compiler, db_adv, pas_dev, devcontainer, sports2020-db${NC}"
                return 1
            fi
            
            echo ""
            echo -e "${CYAN}Building component: $comp${NC}"
            
            local build_args=("-c" "$comp" "-v" "$version")
            
            # Special handling for devcontainer and sports2020-db
            if [[ "$comp" == "devcontainer" ]]; then
                build_args=("-c" "compiler" "-v" "$version" "-d")
            elif [[ "$comp" == "sports2020-db" ]]; then
                build_args=("-c" "db_adv" "-v" "$version" "-s")
            fi
            
            if ! "$build_script" "${build_args[@]}"; then
                echo ""
                echo -e "${RED} Failed to build component: $comp${NC}"
                return 1
            fi
        done
        
        echo ""
        echo -e "${GREEN}All components built successfully!${NC}"
        return 0
        
    elif [[ "$component" == "all" || -z "$component" ]]; then
        # Build all images
        local build_script="$TOOLS_DIR/build-all-images.sh"
        local build_args=("-v" "$version")
        
        if [[ "$devcontainer_only" == "true" ]]; then
            build_args+=("-D")
        fi
        
        if "$build_script" "${build_args[@]}"; then
            echo ""
            echo -e "${GREEN}Docker image build completed!${NC}"
            return 0
        else
            echo ""
            echo -e "${RED}Docker image build failed!${NC}"
            return 1
        fi
    else
        # Build single component
        local build_script="$TOOLS_DIR/build-image.sh"
        local build_args=("-c" "$component" "-v" "$version")
        
        if "$build_script" "${build_args[@]}"; then
            echo ""
            echo -e "${GREEN}Docker image build completed!${NC}"
            return 0
        else
            echo ""
            echo -e "${RED}Docker image build failed!${NC}"
            return 1
        fi
    fi
}

# Validate component dependencies
validate_dependencies() {
    local component="$1"
    local dependency_errors=()
    
    if [[ "$component" == *","* ]]; then
        IFS=',' read -ra components <<< "$component"
        local comp_list=()
        
        for comp in "${components[@]}"; do
            comp=$(echo "$comp" | xargs) # trim whitespace
            comp_list+=("$comp")
        done
        
        # Check dependencies
        for comp in "${comp_list[@]}"; do
            if [[ "$comp" == "devcontainer" ]]; then
                if [[ ! " ${comp_list[*]} " =~ " compiler " ]]; then
                    dependency_errors+=("devcontainer requires compiler to be built first or included in the same build")
                fi
            elif [[ "$comp" == "sports2020-db" ]]; then
                if [[ ! " ${comp_list[*]} " =~ " db_adv " ]]; then
                    dependency_errors+=("sports2020-db requires db_adv to be built first or included in the same build")
                fi
            fi
        done
    fi
    
    if [[ ${#dependency_errors[@]} -gt 0 ]]; then
        echo -e "${RED}Dependency errors:${NC}"
        for error in "${dependency_errors[@]}"; do
            echo -e "${RED}  - $error${NC}"
        done
        echo ""
        return 1
    fi
    
    return 0
}

# Interactive component selection function
get_component_selection() {
    local title="${1:-Select Components to Build}"
    
    # Component definitions
    declare -A components
    declare -A descriptions
    declare -A types
    declare -A selected
    
    components[1]="compiler"
    descriptions[1]="OpenEdge compiler and development tools"
    types[1]="Base"
    
    components[2]="pas_dev"
    descriptions[2]="OpenEdge PAS for development"
    types[2]="Base"
    
    components[3]="db_adv"
    descriptions[3]="OpenEdge database server"
    types[3]="Base"
    
    components[4]="devcontainer"
    descriptions[4]="DevContainer configuration (requires: compiler)"
    types[4]="Dependent"
    
    components[5]="sports2020-db"
    descriptions[5]="Sports2020 database (requires: db_adv)"
    types[5]="Dependent"
    
    # Initialize selections
    for i in {1..5}; do
        selected[$i]=false
    done
    
    while true; do
        clear
        echo -e "${CYAN}================================================================${NC}"
        echo -e "${CYAN} $title${NC}"
        echo -e "${CYAN}================================================================${NC}"
        echo ""
        
        echo -e "${YELLOW}Use number keys to toggle selection, 'm' for manual entry, 'c' to continue, or 'q' to quit${NC}"
        echo ""
        
        # Display base components
        echo -e "${WHITE}Base Images (can be built independently):${NC}"
        for i in 1 2 3; do
            local checkbox="[ ]"
            local color="${GRAY}"
            if [[ "${selected[$i]}" == "true" ]]; then
                checkbox="[X]"
                color="${GREEN}"
            fi
            echo -e "  ${color}$i. $checkbox ${components[$i]} - ${descriptions[$i]}${NC}"
        done
        
        echo ""
        echo -e "${WHITE}Dependent Images (require parent images):${NC}"
        for i in 4 5; do
            local checkbox="[ ]"
            local color="${GRAY}"
            if [[ "${selected[$i]}" == "true" ]]; then
                checkbox="[X]"
                color="${GREEN}"
            fi
            echo -e "  ${color}$i. $checkbox ${components[$i]} - ${descriptions[$i]}${NC}"
        done
        
        echo ""
        echo -e -n "${YELLOW}Selected: ${NC}"
        local selected_names=()
        for i in {1..5}; do
            if [[ "${selected[$i]}" == "true" ]]; then
                selected_names+=("${components[$i]}")
            fi
        done
        
        if [[ ${#selected_names[@]} -gt 0 ]]; then
            echo -e "${GREEN}$(IFS=', '; echo "${selected_names[*]}")${NC}"
        else
            echo -e "${RED}None${NC}"
        fi
        
        echo ""
        echo -e -n "${YELLOW}Enter choice (1-5 to toggle, 'm' for manual entry, 'c' to continue, 'q' to quit): ${NC}"
        read -r choice
        
        case "$choice" in
            1|2|3|4|5)
                if [[ "${selected[$choice]}" == "true" ]]; then
                    selected[$choice]=false
                else
                    selected[$choice]=true
                fi
                ;;
            m|M)
                echo ""
                echo -e "${YELLOW}Enter component(s) to build (comma-separated):${NC}"
                echo -e "${GRAY}Examples: compiler | pas_dev,db_adv | compiler,devcontainer${NC}"
                read -p "Components: " manual_input
                
                if [[ -n "$manual_input" ]]; then
                    # Reset all selections
                    for i in {1..5}; do
                        selected[$i]=false
                    done
                    
                    # Parse manual input
                    IFS=',' read -ra manual_components <<< "$manual_input"
                    local valid_components=("compiler" "pas_dev" "db_adv" "devcontainer" "sports2020-db")
                    local invalid_components=()
                    local valid_input=true
                    
                    for comp in "${manual_components[@]}"; do
                        comp=$(echo "$comp" | xargs) # trim whitespace
                        if [[ ! " ${valid_components[*]} " =~ " ${comp} " ]]; then
                            invalid_components+=("$comp")
                            valid_input=false
                        fi
                    done
                    
                    if [[ "$valid_input" == "true" ]]; then
                        # Set selected components
                        for comp in "${manual_components[@]}"; do
                            comp=$(echo "$comp" | xargs)
                            for i in {1..5}; do
                                if [[ "${components[$i]}" == "$comp" ]]; then
                                    selected[$i]=true
                                    break
                                fi
                            done
                        done
                        echo -e "${GREEN}Manual selection applied: $(IFS=', '; echo "${manual_components[*]}")${NC}"
                    else
                        echo -e "${RED}Invalid component(s): $(IFS=', '; echo "${invalid_components[*]}")${NC}"
                        echo -e "${YELLOW}Valid components: $(IFS=', '; echo "${valid_components[*]}")${NC}"
                    fi
                    sleep 2
                fi
                ;;
            c|C)
                # Check if any components are selected
                local selected_count=0
                for i in {1..5}; do
                    if [[ "${selected[$i]}" == "true" ]]; then
                        ((selected_count++))
                    fi
                done
                
                if [[ $selected_count -eq 0 ]]; then
                    echo -e "${RED}Please select at least one component.${NC}"
                    sleep 2
                    continue
                fi
                
                # Check dependencies
                local dependency_errors=()
                if [[ "${selected[4]}" == "true" && "${selected[1]}" == "false" ]]; then
                    dependency_errors+=("devcontainer requires compiler to be built first or included in the same build")
                fi
                if [[ "${selected[5]}" == "true" && "${selected[3]}" == "false" ]]; then
                    dependency_errors+=("sports2020-db requires db_adv to be built first or included in the same build")
                fi
                
                if [[ ${#dependency_errors[@]} -gt 0 ]]; then
                    echo ""
                    echo -e "${RED}Dependency errors:${NC}"
                    for error in "${dependency_errors[@]}"; do
                        echo -e "${RED}  - $error${NC}"
                    done
                    echo ""
                    echo -e "${YELLOW}Press Enter to continue...${NC}"
                    read -r
                    continue
                fi
                
                # Return selected components as comma-separated string
                local result_components=()
                for i in {1..5}; do
                    if [[ "${selected[$i]}" == "true" ]]; then
                        result_components+=("${components[$i]}")
                    fi
                done
                echo "$(IFS=','; echo "${result_components[*]}")"
                return 0
                ;;
            q|Q)
                return 1
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                sleep 1
                ;;
        esac
    done
}

# Main interactive mode
run_interactive() {
    # Get Docker username first if not provided
    if [[ -z "$DOCKER_USERNAME" ]]; then
        clear
        echo -e "${CYAN}============================================================${NC}"
        echo -e "${CYAN}      OpenEdge Container Build Quickstart                  ${NC}"
        echo -e "${CYAN}============================================================${NC}"
        echo ""
        echo -e "${WHITE}Please enter your Docker Hub username to continue.${NC}"
        echo -e "${GRAY}This will be used to tag the built images.${NC}"
        echo ""
        
        while [[ -z "$DOCKER_USERNAME" ]]; do
            read -p "Docker Username: " DOCKER_USERNAME
            if [[ -z "$DOCKER_USERNAME" ]]; then
                echo -e "${RED}Docker username is required.${NC}"
            fi
        done
    fi
    
    while true; do
        show_menu "$DOCKER_USERNAME"
        choice=$(get_user_choice "Select an option (1-4): " "1" "2" "3" "4")
        
        if [[ "$choice" == "4" ]]; then
            echo -e "${YELLOW}Exiting...${NC}"
            return
        fi
        
        # Get version if not provided
        if [[ -z "$VERSION" ]]; then
            echo ""
            read -p "Enter OpenEdge version (e.g., 12.8.9): " VERSION
        fi
        
        case "$choice" in
            "1")
                # Generate response.ini
                devcontainer_choice=$(get_user_choice "Only generate response.ini files for DevContainer configuration (pas_dev,compiler,db_adv)? (y/n): " "y" "n")
                devcontainer_flag="false"
                if [[ "$devcontainer_choice" == "y" ]]; then
                    devcontainer_flag="true"
                fi
                
                invoke_generate_response_ini "$VERSION" "$LICENSE_FILE" "$FORCE" "$devcontainer_flag"
                
                echo ""
                read -p "Press Enter to continue"
                ;;
            "2")
                # Create all images for DevContainer configuration
                echo ""
                echo -e "${CYAN}Building all images required for DevContainer configuration...${NC}"
                echo -e "${GRAY}This will build: compiler, pas_dev, db_adv, devcontainer, sports2020-db${NC}"
                
                invoke_build_images "all" "$VERSION" "$DOCKER_USERNAME" "true"
                
                echo ""
                read -p "Press Enter to continue"
                ;;
            "3")
                # Create specific container images
                comp=$(get_component_selection "Select Components to Build")
                
                if [[ $? -ne 0 ]]; then
                    # User chose to quit
                    continue
                fi
                
                invoke_build_images "$comp" "$VERSION" "$DOCKER_USERNAME" "false"
                
                echo ""
                read -p "Press Enter to continue"
                ;;
        esac
    done
}

# Main execution
main() {
    # Parse command line arguments (basic support)
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--action)
                ACTION="$2"
                shift 2
                ;;
            -v|--version)
                VERSION="$2"
                shift 2
                ;;
            -u|--username)
                DOCKER_USERNAME="$2"
                shift 2
                ;;
            -c|--component)
                COMPONENT="$2"
                shift 2
                ;;
            -l|--license)
                LICENSE_FILE="$2"
                shift 2
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -b|--batch)
                BATCH=true
                shift
                ;;
            -h|--help)
                echo "OpenEdge Container Build Quickstart"
                echo ""
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  -a, --action ACTION     Action to perform: generate, build, or both"
                echo "  -v, --version VERSION   OpenEdge version (e.g., 12.8.9)"
                echo "  -u, --username USER     Docker Hub username"
                echo "  -c, --component COMP    Component to build"
                echo "  -l, --license FILE      License addendum file"
                echo "  -f, --force             Skip confirmation prompts"
                echo "  -b, --batch             Run in batch mode"
                echo "  -h, --help              Show this help"
                echo ""
                echo "Examples:"
                echo "  $0                                    # Interactive mode"
                echo "  $0 -a build -v 12.8.9 -u myuser     # Batch mode"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use -h or --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Run in appropriate mode
    if [[ "$BATCH" == "true" || -n "$ACTION" ]]; then
        # Batch mode (basic implementation)
        if [[ -z "$ACTION" ]]; then
            echo -e "${RED}Error: -a/--action parameter is required in batch mode${NC}"
            echo "Use -a generate, -a build, or -a both"
            exit 1
        fi
        
        if [[ -z "$VERSION" ]]; then
            echo -e "${RED}Error: -v/--version parameter is required${NC}"
            exit 1
        fi
        
        success=true
        
        if [[ "$ACTION" == "generate" || "$ACTION" == "both" ]]; then
            if ! invoke_generate_response_ini "$VERSION" "$LICENSE_FILE" "$FORCE" "false"; then
                success=false
            fi
        fi
        
        if [[ "$success" == "true" && ("$ACTION" == "build" || "$ACTION" == "both") ]]; then
            if [[ -z "$COMPONENT" ]]; then
                COMPONENT="all"
            fi
            if ! invoke_build_images "$COMPONENT" "$VERSION" "$DOCKER_USERNAME" "false"; then
                success=false
            fi
        fi
        
        if [[ "$success" == "false" ]]; then
            exit 1
        fi
    else
        # Interactive mode
        run_interactive
    fi
}

# Run main function
main "$@"
