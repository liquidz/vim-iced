.PHONY: vital test lint clean

PLUGIN_NAME = iced
VITAL_MODULES = Data.List \
				Data.String \
				Vim.Buffer \
				Vim.BufferManager

vital:
	vim -c "Vitalize . --name=$(PLUGIN_NAME) $(VITAL_MODULES)" -c q

test:
	themis

lint:
	find . -name "*.vim" | grep -v vital | xargs vint

clean:
	/bin/rm -rf autoload/vital*

