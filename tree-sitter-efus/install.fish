#!/usr/bin/env fish

function install_helix -d "Install efus grammar for Helix editor"
    set -l script_dir (dirname (status --current-filename))
    set -l helix_config_dir "$HOME/.config/helix"
    set -l helix_runtime_dir "$helix_config_dir/runtime"
    set -l grammar_source_dir "$script_dir"
    set -l grammar_name "tree-sitter-efus"
    set -l query_dir_name "efus"

    echo "Installing efus grammar for Helix..."

    # Ensure target directories exist
    mkdir -p "$helix_runtime_dir/grammars"
    mkdir -p "$helix_runtime_dir/queries"

    # Clean up previous installations to prevent errors
    echo "Cleaning up old installation..."
    rm -rf "$helix_runtime_dir/grammars/$grammar_name"
    rm -rf "$helix_runtime_dir/queries/$query_dir_name"
    rm -f "$helix_runtime_dir/grammars/efus.so"

    # 1. Symlink the grammar source directory
    echo "Symlinking grammar source..."
    if ln -s "$grammar_source_dir" "$helix_runtime_dir/grammars/$grammar_name"
        echo "  -> Success"
    else
        echo "  -> Failed to create symlink for grammar source."
        return 1
    end

    # 2. Copy the queries directory
    echo "Copying queries..."
    if cp -r "$grammar_source_dir/queries" "$helix_runtime_dir/queries/$query_dir_name"
        echo "  -> Success"
    else
        echo "  -> Failed to copy queries."
        return 1
    end

    echo ""
    echo "Installation complete!"
    echo ""
    echo "Next steps:"
    echo "1. Ensure your languages.toml is configured correctly:"
    echo "   (in $helix_config_dir/languages.toml)"
    echo ""
    echo '   [[grammar]]'
    echo '   name = "efus"'
    echo "   source = { path = \"$helix_runtime_dir/grammars/$grammar_name\" }"
    echo ""
    echo "2. Build the grammar in Helix:"
    echo "   hx --grammar build efus"
    echo ""
end

# Main command dispatcher
if count $argv > 0
    switch $argv[1]
        case helix
            install_helix
        case '*'
            echo "Unknown command: $argv[1]"
            echo "Usage: ./install.fish helix"
            exit 1
    end
else
    echo "Usage: ./install.fish <command>"
    echo "Available commands: helix"
end
