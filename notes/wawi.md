# Wasp Web Interface

## [[context]] wawi

API functions for wasp (or any other wasm language) to communicate with the Web:

```text
[[navigate]] : url			|
[[alert]] : text   			| forward to js alert
[[log]]   : text			| forward to js Console.log and maybe other	( log text ≠ log number )
[[paint]] : data	 		| add or create 2D/3D elements, objects and scenes
[[fetch]] : url -> data		|
```

### Examples
```html
<script type="wasp">
    fetch test.com
    alert √9
</script>
```